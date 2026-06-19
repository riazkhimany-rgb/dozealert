import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../cache/gtfs_cache_store.dart';
import '../models/gtfs_feed_info.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';

class GtfsImportResult {
  const GtfsImportResult({
    required this.feedInfo,
    required this.agencies,
    required this.routes,
    required this.stops,
  });

  final GtfsFeedInfo feedInfo;
  final List<TransitAgency> agencies;
  final List<TransitRoute> routes;
  final List<TransitStop> stops;
}

class GtfsImportService {
  GtfsImportService(this._cacheStore);

  final GtfsCacheStore _cacheStore;

  static const supportedExamples = <String>[
    'GO Transit',
    'TTC',
    'STM Montreal',
    'Exo Montreal',
    'Amtrak',
    'National Rail',
  ];

  Future<List<GtfsCachedFeed>> loadCache() {
    return _cacheStore.loadAllFeeds();
  }

  Future<List<GtfsFeedInfo>> loadFeedInfos() {
    return _cacheStore.loadFeedInfos();
  }

  Future<GtfsImportResult> importZipBytes({
    required List<int> bytes,
    required String fileName,
    String? feedName,
  }) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final files = <String, String>{};

    for (final file in archive) {
      if (file.isFile) {
        final name = file.name.split('/').last.toLowerCase();
        files[name] = utf8.decode(file.content as List<int>);
      }
    }

    final agenciesRaw = _parseCsv(files['agency.txt'] ?? '');
    final routesRaw = _parseCsv(files['routes.txt'] ?? '');
    final stopsRaw = _parseCsv(files['stops.txt'] ?? '');
    final tripsRaw = _parseCsv(files['trips.txt'] ?? '');
    final stopTimesRaw = _parseCsv(files['stop_times.txt'] ?? '');
    final calendarRaw = _parseCsv(files['calendar.txt'] ?? '');

    if (agenciesRaw.isEmpty || routesRaw.isEmpty || stopsRaw.isEmpty) {
      throw FormatException(
        'Invalid GTFS feed: agency.txt, routes.txt, and stops.txt are required.',
      );
    }

    final resolvedFeedName = feedName ??
        agenciesRaw.first['agency_name'] ??
        fileName.replaceAll('.zip', '');

    final feedId = _feedIdFromName(resolvedFeedName);
    final country = _inferCountry(resolvedFeedName);
    final city = _inferCity(resolvedFeedName);

    final agencies = agenciesRaw
        .map(
          (row) => TransitAgency(
            agencyId: row['agency_id'] ?? feedId,
            agencyName: row['agency_name'] ?? resolvedFeedName,
            country: country,
            city: city,
          ),
        )
        .toList(growable: false);

    final routes = routesRaw
        .map(
          (row) {
            final routeId = row['route_id'] ?? '';
            final routeName =
                row['route_long_name'] ?? row['route_short_name'] ?? routeId;
            final agencyId = row['agency_id'] ?? agencies.first.agencyId;
            return TransitRoute(
              routeId: '${feedId}_$routeId',
              routeName: routeName,
              agencyId: agencyId,
              country: country,
              lineName: routeName,
              transitSystem: resolvedFeedName,
            );
          },
        )
        .where((route) => route.routeId.isNotEmpty)
        .toList(growable: false);

    final stopLookup = <String, Map<String, String>>{
      for (final row in stopsRaw)
        if (row['stop_id'] != null) row['stop_id']!: row,
    };

    final tripRouteLookup = <String, String>{
      for (final row in tripsRaw)
        if (row['trip_id'] != null && row['route_id'] != null)
          row['trip_id']!: row['route_id']!,
    };

    final routeTripStops = <String, Map<int, String>>{};
    for (final row in stopTimesRaw) {
      final tripId = row['trip_id'];
      final stopId = row['stop_id'];
      final sequence = int.tryParse(row['stop_sequence'] ?? '');
      if (tripId == null || stopId == null || sequence == null) {
        continue;
      }

      final routeId = tripRouteLookup[tripId];
      if (routeId == null) {
        continue;
      }

      final fullRouteId = '${feedId}_$routeId';
      routeTripStops.putIfAbsent(fullRouteId, () => {})[sequence] = stopId;
    }

    final stops = <TransitStop>[];
    routeTripStops.forEach((routeId, sequenceMap) {
      final sortedEntries = sequenceMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in sortedEntries) {
        final stopRow = stopLookup[entry.value];
        if (stopRow == null) {
          continue;
        }

        final latitude = double.tryParse(stopRow['stop_lat'] ?? '');
        final longitude = double.tryParse(stopRow['stop_lon'] ?? '');
        if (latitude == null || longitude == null) {
          continue;
        }

        stops.add(
          TransitStop(
            stopId: '$routeId:${entry.key}',
            stopName: stopRow['stop_name'] ?? entry.value,
            latitude: latitude,
            longitude: longitude,
            routeId: routeId,
            stopSequence: entry.key,
          ),
        );
      }
    });

    if (stops.isEmpty) {
      for (final row in stopsRaw) {
        final latitude = double.tryParse(row['stop_lat'] ?? '');
        final longitude = double.tryParse(row['stop_lon'] ?? '');
        final stopId = row['stop_id'];
        if (latitude == null || longitude == null || stopId == null) {
          continue;
        }

        final fallbackRoute = routes.isNotEmpty ? routes.first.routeId : feedId;
        stops.add(
          TransitStop(
            stopId: '${feedId}_$stopId',
            stopName: row['stop_name'] ?? stopId,
            latitude: latitude,
            longitude: longitude,
            routeId: fallbackRoute,
            stopSequence: stops.length + 1,
          ),
        );
      }
    }

    final feedInfo = GtfsFeedInfo(
      feedId: feedId,
      feedName: resolvedFeedName,
      agencyCount: agencies.length,
      routeCount: routes.length,
      stopCount: stops.length,
      lastUpdated: DateTime.now(),
      sourceFileName: fileName,
    );

    debugPrint(
      'GtfsImportService: parsed ${feedInfo.feedName} '
      '(${feedInfo.agencyCount} agencies, ${feedInfo.routeCount} routes, '
      '${feedInfo.stopCount} stops, calendar rows: ${calendarRaw.length})',
    );

    await _cacheStore.saveFeed(
      info: feedInfo,
      agencies: agencies,
      routes: routes,
      stops: stops,
    );

    return GtfsImportResult(
      feedInfo: feedInfo,
      agencies: agencies,
      routes: routes,
      stops: stops,
    );
  }

  Future<void> downloadGtfsFeed(String feedId) async {
    debugPrint('GtfsImportService: downloadGtfsFeed($feedId) not implemented.');
  }

  Future<void> updateFeed(String feedId) async {
    debugPrint('GtfsImportService: updateFeed($feedId) not implemented.');
  }

  Future<List<GtfsCachedFeed>> refreshCache() async {
    debugPrint('GtfsImportService: refreshCache() reloading local cache.');
    return loadCache();
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

  String _feedIdFromName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
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
    if (normalized.contains('montreal') || normalized.contains('exo')) {
      return 'Montreal';
    }
    if (normalized.contains('vancouver') || normalized.contains('translink')) {
      return 'Vancouver';
    }
    if (normalized.contains('ottawa') || normalized.contains('oc transpo')) {
      return 'Ottawa';
    }
    if (normalized.contains('national rail')) {
      return 'National';
    }
    if (normalized.contains('underground')) {
      return 'London';
    }
    if (normalized.contains('amtrak')) {
      return 'National';
    }
    return 'Toronto';
  }
}
