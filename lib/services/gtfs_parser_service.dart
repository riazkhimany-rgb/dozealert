import 'dart:collection';
import 'dart:convert';

import 'package:archive/archive.dart';

import '../models/gtfs_feed_info.dart';
import '../models/gtfs_parse_schema.dart';
import '../models/route_shape_polyline.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import '../models/transit_vehicle_type.dart';
import '../utils/app_log.dart';
import '../utils/gtfs_stop_name_utils.dart';
import '../utils/gtfs_vehicle_rules.dart';

class GtfsParseResult {
  const GtfsParseResult({
    required this.feedInfo,
    required this.agencies,
    required this.routes,
    required this.stops,
    this.shapes = const [],
  });

  final GtfsFeedInfo feedInfo;
  final List<TransitAgency> agencies;
  final List<TransitRoute> routes;
  final List<TransitStop> stops;
  final List<RouteShapePolyline> shapes;
}

class GtfsParserService {
  static const _requiredGtfsFiles = {
    'agency.txt',
    'routes.txt',
    'stops.txt',
    'trips.txt',
    'stop_times.txt',
  };

  GtfsParseResult parseZipBytes({
    required List<int> bytes,
    required String fileName,
    required GtfsFeedInfo seedFeed,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <String, String>{};

    for (final file in archive) {
      if (!file.isFile) {
        continue;
      }
      final name = file.name.split('/').last.toLowerCase();
      if (!_requiredGtfsFiles.contains(name) && name != 'shapes.txt') {
        continue;
      }
      files[name] = utf8.decode(file.content as List<int>);
    }

    final agenciesRaw = _parseCsv(files['agency.txt'] ?? '');
    final routesRaw = _parseCsv(files['routes.txt'] ?? '');
    final stopsRaw = _parseCsv(files['stops.txt'] ?? '');
    final tripsRaw = _parseCsv(files['trips.txt'] ?? '');
    final stopTimesRaw = _parseCsv(files['stop_times.txt'] ?? '');

    if (agenciesRaw.isEmpty || routesRaw.isEmpty || stopsRaw.isEmpty) {
      throw FormatException(
        'Invalid GTFS feed: agency.txt, routes.txt, and stops.txt are required.',
      );
    }

    final feedId = seedFeed.feedId;
    final resolvedFeedName = seedFeed.agencyName.isNotEmpty
        ? seedFeed.agencyName
        : agenciesRaw.first['agency_name'] ??
            fileName.replaceAll('.zip', '');
    final country = _inferCountry(resolvedFeedName);
    final city = _inferCity(resolvedFeedName);

    final agencies = agenciesRaw
        .map(
          (row) => TransitAgency(
            agencyId: row['agency_id'] ?? feedId,
            agencyName: row['agency_name'] ?? resolvedFeedName,
            country: country,
            city: city,
            supportsRealtime: seedFeed.supportsRealtime,
          ),
        )
        .toList(growable: false);

    final routes = routesRaw
        .map(
          (row) {
            final routeId = row['route_id'] ?? '';
            final shortName = (row['route_short_name'] ?? '').trim();
            final longName = (row['route_long_name'] ?? '').trim();
            final lineName = shortName.isNotEmpty
                ? shortName
                : (longName.isNotEmpty ? longName : routeId);
            final routeName = longName.isNotEmpty
                ? longName
                : (shortName.isNotEmpty ? shortName : routeId);
            final agencyId = row['agency_id'] ?? agencies.first.agencyId;
            return TransitRoute(
              routeId: '${feedId}_$routeId',
              routeName: routeName,
              agencyId: agencyId,
              country: country,
              lineName: lineName,
              routeShortName: shortName.isEmpty ? null : shortName,
              transitSystem: resolvedFeedName,
              vehicleType: _vehicleTypeForRoute(
                routeType: row['route_type'],
                defaultType: seedFeed.primaryVehicleType,
                feedId: feedId,
                routeShortName: shortName,
                routeLongName: longName,
              ),
            );
          },
        )
        .where((route) => route.routeId.isNotEmpty)
        .toList(growable: false);

    final stopLookup = <String, Map<String, String>>{
      for (final row in stopsRaw)
        if (row['stop_id'] != null) row['stop_id']!: row,
    };

    final tripMeta = <String, ({String routeId, String directionId, String headsign, String shapeId})>{};
    final directionIdsByRoute = <String, Set<String>>{};
    for (final row in tripsRaw) {
      final tripId = row['trip_id'];
      final routeId = row['route_id'];
      if (tripId == null || routeId == null) {
        continue;
      }
      final directionId = (row['direction_id'] ?? '').trim();
      final headsign = (row['trip_headsign'] ?? '').trim();
      final shapeId = (row['shape_id'] ?? '').trim();
      tripMeta[tripId] = (
        routeId: routeId,
        directionId: directionId.isEmpty ? '0' : directionId,
        headsign: headsign,
        shapeId: shapeId,
      );
      directionIdsByRoute
          .putIfAbsent(routeId, () => <String>{})
          .add(directionId.isEmpty ? '0' : directionId);
    }

    final tripStopSequences = <String, SplayTreeMap<int, String>>{};
    final tripHeadsignAtStop = <String, Map<int, String>>{};
    for (final row in stopTimesRaw) {
      final tripId = row['trip_id'];
      final stopId = row['stop_id'];
      final sequence = int.tryParse(row['stop_sequence'] ?? '');
      if (tripId == null || stopId == null || sequence == null) {
        continue;
      }

      tripStopSequences
          .putIfAbsent(tripId, SplayTreeMap.new)
          .putIfAbsent(sequence, () => stopId);

      final stopHeadsign = (row['stop_headsign'] ?? '').trim();
      if (stopHeadsign.isNotEmpty) {
        tripHeadsignAtStop
            .putIfAbsent(tripId, () => {})
            .putIfAbsent(sequence, () => stopHeadsign);
      }
    }

    final bestPatternByKey = <String, List<String>>{};
    final bestHeadsignByKey = <String, String>{};
    final bestShapeByKey = <String, String>{};

    for (final entry in tripStopSequences.entries) {
      final meta = tripMeta[entry.key];
      if (meta == null) {
        continue;
      }

      final fullRouteId = '${feedId}_${meta.routeId}';
      final resolvedHeadsign = _resolveTripHeadsign(
        meta.headsign,
        tripHeadsignAtStop[entry.key],
      );
      final patternKey = _patternStorageKey(
        fullRouteId: fullRouteId,
        routeId: meta.routeId,
        directionId: meta.directionId,
        headsign: resolvedHeadsign,
        directionIdsByRoute: directionIdsByRoute,
      );
      final orderedStopIds = entry.value.values.toList(growable: false);
      final existing = bestPatternByKey[patternKey];
      final existingHeadsign = bestHeadsignByKey[patternKey] ?? '';

      if (existing == null ||
          orderedStopIds.length > existing.length ||
          (orderedStopIds.length == existing.length &&
              existingHeadsign.isEmpty &&
              resolvedHeadsign.isNotEmpty)) {
        bestPatternByKey[patternKey] = orderedStopIds;
        bestHeadsignByKey[patternKey] = resolvedHeadsign;
        if (meta.shapeId.isNotEmpty) {
          bestShapeByKey[patternKey] = meta.shapeId;
        }
      }
    }

    final shapesByShapeId = _parseShapes(files['shapes.txt'] ?? '');
    final routeShapes = <RouteShapePolyline>[];
    for (final entry in bestPatternByKey.entries) {
      final shapeId = bestShapeByKey[entry.key];
      if (shapeId == null) {
        continue;
      }
      final points = shapesByShapeId[shapeId];
      if (points == null || points.length < 2) {
        continue;
      }

      final separatorIndex = entry.key.lastIndexOf('|');
      final routeId = entry.key.substring(0, separatorIndex);
      final patternToken = entry.key.substring(separatorIndex + 1);
      routeShapes.add(
        RouteShapePolyline(
          routeId: routeId,
          patternKey: _patternKeyFromStorageToken(patternToken),
          points: points,
        ),
      );
    }

    final stops = <TransitStop>[];
    for (final entry in bestPatternByKey.entries) {
      final separatorIndex = entry.key.lastIndexOf('|');
      final routeId = entry.key.substring(0, separatorIndex);
      final patternToken = entry.key.substring(separatorIndex + 1);
      final stopIdMiddle = _stopIdMiddleFromPatternToken(patternToken);

      final seenLocationKeys = <String>{};
      var displaySequence = 0;
      for (final gtfsStopId in entry.value) {
        final resolved = _resolveStopRow(stopLookup, gtfsStopId);
        if (resolved == null) {
          continue;
        }

        final latitude = double.tryParse(resolved['stop_lat'] ?? '');
        final longitude = double.tryParse(resolved['stop_lon'] ?? '');
        if (latitude == null || longitude == null) {
          continue;
        }

        final stopName = GtfsStopNameUtils.normalize(
          resolved['stop_name'] ?? gtfsStopId,
        );
        final locationKey =
            '$stopName|${latitude.toStringAsFixed(5)}|${longitude.toStringAsFixed(5)}';
        if (seenLocationKeys.contains(locationKey)) {
          continue;
        }
        seenLocationKeys.add(locationKey);

        displaySequence++;
        stops.add(
          TransitStop(
            stopId: '$routeId:$stopIdMiddle:s$displaySequence',
            stopName: stopName,
            latitude: latitude,
            longitude: longitude,
            routeId: routeId,
            stopSequence: displaySequence,
          ),
        );
      }
    }

    if (stops.isEmpty) {
      for (final row in stopsRaw) {
        final stopId = row['stop_id'];
        if (stopId == null) {
          continue;
        }
        final resolved = _resolveStopRow(stopLookup, stopId);
        if (resolved == null) {
          continue;
        }
        final latitude = double.tryParse(resolved['stop_lat'] ?? '');
        final longitude = double.tryParse(resolved['stop_lon'] ?? '');
        if (latitude == null || longitude == null) {
          continue;
        }

        final fallbackRoute = routes.isNotEmpty ? routes.first.routeId : feedId;
        stops.add(
          TransitStop(
            stopId: '${feedId}_$stopId',
            stopName: GtfsStopNameUtils.normalize(
              resolved['stop_name'] ?? stopId,
            ),
            latitude: latitude,
            longitude: longitude,
            routeId: fallbackRoute,
            stopSequence: stops.length + 1,
          ),
        );
      }
    }

    final feedInfo = seedFeed.copyWith(
      agencyName: resolvedFeedName,
      agencyCount: agencies.length,
      routeCount: routes.length,
      stopCount: stops.length,
      lastUpdated: DateTime.now(),
      sourceFileName: fileName,
      status: GtfsFeedStatus.downloaded,
      errorMessage: null,
      parseSchemaVersion: GtfsParseSchema.current,
    );

    AppLog.d(
      'GtfsParserService: parsed ${feedInfo.agencyName} '
      '(${feedInfo.agencyCount} agencies, ${feedInfo.routeCount} routes, '
      '${feedInfo.stopCount} stops)',
    );

    return GtfsParseResult(
      feedInfo: feedInfo,
      agencies: agencies,
      routes: routes,
      stops: stops,
      shapes: routeShapes,
    );
  }

  Map<String, List<RouteShapePoint>> _parseShapes(String content) {
    if (content.trim().isEmpty) {
      return const {};
    }

    final rows = _parseCsv(content);
    final grouped = <String, SplayTreeMap<int, RouteShapePoint>>{};
    for (final row in rows) {
      final shapeId = row['shape_id'];
      final sequence = int.tryParse(row['shape_pt_sequence'] ?? '');
      final latitude = double.tryParse(row['shape_pt_lat'] ?? '');
      final longitude = double.tryParse(row['shape_pt_lon'] ?? '');
      if (shapeId == null ||
          sequence == null ||
          latitude == null ||
          longitude == null) {
        continue;
      }

      grouped
          .putIfAbsent(shapeId, SplayTreeMap.new)
          .putIfAbsent(
            sequence,
            () => RouteShapePoint(
              latitude: latitude,
              longitude: longitude,
            ),
          );
    }

    return {
      for (final entry in grouped.entries)
        entry.key: entry.value.values.toList(growable: false),
    };
  }

  static String _patternKeyFromStorageToken(String patternToken) {
    if (patternToken.startsWith('d:') || patternToken.startsWith('h:')) {
      return patternToken;
    }
    return 'd:$patternToken';
  }

  static String _resolveTripHeadsign(
    String tripHeadsign,
    Map<int, String>? stopHeadsigns,
  ) {
    if (tripHeadsign.isNotEmpty) {
      return tripHeadsign;
    }
    if (stopHeadsigns == null || stopHeadsigns.isEmpty) {
      return '';
    }
    final counts = <String, int>{};
    for (final headsign in stopHeadsigns.values) {
      counts[headsign] = (counts[headsign] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  static bool _routeNeedsHeadsignGrouping(
    String routeId,
    Map<String, Set<String>> directionIdsByRoute,
  ) {
    final directions = directionIdsByRoute[routeId];
    return directions == null || directions.length <= 1;
  }

  static String _patternStorageKey({
    required String fullRouteId,
    required String routeId,
    required String directionId,
    required String headsign,
    required Map<String, Set<String>> directionIdsByRoute,
  }) {
    if (_routeNeedsHeadsignGrouping(routeId, directionIdsByRoute) &&
        headsign.isNotEmpty) {
      return '$fullRouteId|h:${_sanitizeHeadsign(headsign)}';
    }
    return '$fullRouteId|d:$directionId';
  }

  static String _stopIdMiddleFromPatternToken(String patternToken) {
    if (patternToken.startsWith('h:')) {
      return 'h${_sanitizeHeadsign(patternToken.substring(2))}';
    }
    if (patternToken.startsWith('d:')) {
      return 'd${patternToken.substring(2)}';
    }
    return 'd$patternToken';
  }

  static String _sanitizeHeadsign(String headsign) {
    return headsign
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static Map<String, String>? _resolveStopRow(
    Map<String, Map<String, String>> stopLookup,
    String stopId,
  ) {
    final row = stopLookup[stopId];
    if (row == null) {
      return null;
    }

    final parentId = (row['parent_station'] ?? '').trim();
    if (parentId.isEmpty) {
      return row;
    }

    final parent = stopLookup[parentId];
    if (parent == null) {
      return row;
    }

    return {
      ...parent,
      'stop_id': parent['stop_id'] ?? parentId,
      'stop_name': parent['stop_name'] ?? row['stop_name'] ?? stopId,
    };
  }

  TransitVehicleType _vehicleTypeForRoute({
    required String? routeType,
    required TransitVehicleType defaultType,
    required String feedId,
    required String routeShortName,
    required String routeLongName,
  }) {
    final typeCode = int.tryParse(routeType?.trim() ?? '');
    if (typeCode != null) {
      return switch (typeCode) {
        0 when defaultType == TransitVehicleType.lightRail =>
          TransitVehicleType.lightRail,
        0 => TransitVehicleType.streetcar,
        1 => TransitVehicleType.subway,
        2 => TransitVehicleType.train,
        3 => TransitVehicleType.bus,
        11 => TransitVehicleType.bus,
        _ => _inferVehicleTypeFromRouteNames(
          feedId: feedId,
          routeShortName: routeShortName,
          routeLongName: routeLongName,
          defaultType: defaultType,
        ),
      };
    }

    return _inferVehicleTypeFromRouteNames(
      feedId: feedId,
      routeShortName: routeShortName,
      routeLongName: routeLongName,
      defaultType: defaultType,
    );
  }

  TransitVehicleType _inferVehicleTypeFromRouteNames({
    required String feedId,
    required String routeShortName,
    required String routeLongName,
    required TransitVehicleType defaultType,
  }) {
    return GtfsVehicleRules.inferFromRouteNames(
      feedId: feedId,
      routeShortName: routeShortName,
      routeLongName: routeLongName,
      defaultType: defaultType,
    );
  }

  List<Map<String, String>> _parseCsv(String content) {
    if (content.trim().isEmpty) {
      return const [];
    }

    final lines = content
        .replaceAll('\r\n', '\n')
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const [];
    }

    final headers = _splitCsvLine(lines.first);
    final rows = <Map<String, String>>[];

    for (var i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      final row = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        if (j < values.length) {
          row[headers[j]] = values[j];
        }
      }
      rows.add(row);
    }

    return rows;
  }

  List<String> _splitCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    values.add(buffer.toString());
    return values;
  }

  String _inferCountry(String feedName) {
    final normalized = feedName.toLowerCase();
    if (normalized.contains('amtrak') || normalized.contains('mta')) {
      return 'United States';
    }
    if (normalized.contains('national rail') ||
        normalized.contains('underground')) {
      return 'United Kingdom';
    }
    return 'Canada';
  }

  String _inferCity(String feedName) {
    final normalized = feedName.toLowerCase();
    if (normalized.contains('montreal') ||
        normalized.contains('exo') ||
        normalized.contains('stm')) {
      return 'Montreal';
    }
    if (normalized.contains('vancouver') || normalized.contains('translink')) {
      return 'Vancouver';
    }
    if (normalized.contains('victoria')) {
      return 'Victoria';
    }
    if (normalized.contains('kelowna')) {
      return 'Kelowna';
    }
    if (normalized.contains('nanaimo')) {
      return 'Nanaimo';
    }
    if (normalized.contains('kamloops')) {
      return 'Kamloops';
    }
    if (normalized.contains('calgary')) {
      return 'Calgary';
    }
    if (normalized.contains('edmonton')) {
      return 'Edmonton';
    }
    if (normalized.contains('winnipeg')) {
      return 'Winnipeg';
    }
    if (normalized.contains('halifax')) {
      return 'Halifax';
    }
    if (normalized.contains('ottawa') || normalized.contains('oc transpo')) {
      return 'Ottawa';
    }
    if (normalized.contains('waterloo') || normalized.contains('grt')) {
      return 'Waterloo';
    }
    if (normalized.contains('hamilton') || normalized.contains('hsr')) {
      return 'Hamilton';
    }
    return 'Toronto';
  }
}
