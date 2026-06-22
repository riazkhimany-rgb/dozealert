import 'dart:convert';
import 'dart:io';

import '../cache/gtfs_cache_store.dart';
import '../models/gtfs_feed_info.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import '../models/transit_vehicle_type.dart';
import '../services/gtfs_parser_service.dart';

class GtfsParseRequest {
  const GtfsParseRequest({
    required this.bytes,
    required this.fileName,
    required this.seedFeedJson,
  });

  final List<int> bytes;
  final String fileName;
  final Map<String, dynamic> seedFeedJson;
}

class GtfsCacheEncodeRequest {
  const GtfsCacheEncodeRequest({
    required this.feedInfoJson,
    required this.agenciesJson,
    required this.routesJson,
    required this.stopsJson,
  });

  final Map<String, dynamic> feedInfoJson;
  final List<Map<String, dynamic>> agenciesJson;
  final List<Map<String, dynamic>> routesJson;
  final List<Map<String, dynamic>> stopsJson;
}

GtfsParseResult parseGtfsZipInIsolate(GtfsParseRequest request) {
  final parser = GtfsParserService();
  final seedFeed = GtfsFeedInfo.fromJson(request.seedFeedJson);
  return parser.parseZipBytes(
    bytes: request.bytes,
    fileName: request.fileName,
    seedFeed: seedFeed,
  );
}

Map<String, String> encodeGtfsCacheFilesInIsolate(GtfsCacheEncodeRequest request) {
  return {
    'feed_info.json': jsonEncode(request.feedInfoJson),
    'agencies.json': jsonEncode(request.agenciesJson),
    'routes.json': jsonEncode(request.routesJson),
    'stops.json': jsonEncode(request.stopsJson),
  };
}

GtfsCachedFeed loadGtfsCachedFeedInIsolate(String feedDirectoryPath) {
  final infoFile = File('$feedDirectoryPath/feed_info.json');
  if (!infoFile.existsSync()) {
    throw FormatException('Missing feed_info.json in $feedDirectoryPath');
  }

  final info = GtfsFeedInfo.fromJson(
    jsonDecode(infoFile.readAsStringSync()) as Map<String, dynamic>,
  );
  return GtfsCachedFeed(
    info: info,
    agencies: _readAgencies('$feedDirectoryPath/agencies.json'),
    routes: _readRoutes('$feedDirectoryPath/routes.json'),
    stops: _readStops('$feedDirectoryPath/stops.json'),
  );
}

List<GtfsCachedFeed> loadAllGtfsCachedFeedsInIsolate(String cacheDirectoryPath) {
  final cacheDir = Directory(cacheDirectoryPath);
  if (!cacheDir.existsSync()) {
    return const [];
  }

  final feeds = <GtfsCachedFeed>[];
  for (final entity in cacheDir.listSync()) {
    if (entity is! Directory) {
      continue;
    }

    final infoFile = File('${entity.path}/feed_info.json');
    if (!infoFile.existsSync()) {
      continue;
    }

    try {
      feeds.add(loadGtfsCachedFeedInIsolate(entity.path));
    } catch (_) {
      continue;
    }
  }

  feeds.sort((a, b) {
    final aDate = a.info.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.info.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  return feeds;
}

List<TransitAgency> _readAgencies(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const [];
  }
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return decoded
      .map(
        (entry) => TransitAgency(
          agencyId: entry['agencyId'] as String,
          agencyName: entry['agencyName'] as String,
          country: entry['country'] as String,
          city: entry['city'] as String,
          supportsRealtime: entry['supportsRealtime'] as bool? ?? false,
        ),
      )
      .toList(growable: false);
}

List<TransitRoute> _readRoutes(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const [];
  }
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return decoded
      .map(
        (entry) => TransitRoute(
          routeId: entry['routeId'] as String,
          routeName: entry['routeName'] as String,
          agencyId: entry['agencyId'] as String,
          country: entry['country'] as String,
          lineName: entry['lineName'] as String,
          transitSystem: entry['transitSystem'] as String,
          vehicleType: TransitVehicleTypeX.fromName(
            entry['vehicleType'] as String?,
          ),
        ),
      )
      .toList(growable: false);
}

List<TransitStop> _readStops(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const [];
  }
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return decoded
      .map(
        (entry) => TransitStop(
          stopId: entry['stopId'] as String,
          stopName: entry['stopName'] as String,
          latitude: (entry['latitude'] as num).toDouble(),
          longitude: (entry['longitude'] as num).toDouble(),
          routeId: entry['routeId'] as String,
          stopSequence: entry['stopSequence'] as int,
        ),
      )
      .toList(growable: false);
}

Map<String, dynamic> agencyToJson(TransitAgency agency) {
  return {
    'agencyId': agency.agencyId,
    'agencyName': agency.agencyName,
    'country': agency.country,
    'city': agency.city,
    'supportsRealtime': agency.supportsRealtime,
  };
}

Map<String, dynamic> routeToJson(TransitRoute route) {
  return {
    'routeId': route.routeId,
    'routeName': route.routeName,
    'agencyId': route.agencyId,
    'country': route.country,
    'lineName': route.lineName,
    'transitSystem': route.transitSystem,
    'vehicleType': route.vehicleType.name,
  };
}

Map<String, dynamic> stopToJson(TransitStop stop) {
  return {
    'stopId': stop.stopId,
    'stopName': stop.stopName,
    'latitude': stop.latitude,
    'longitude': stop.longitude,
    'routeId': stop.routeId,
    'stopSequence': stop.stopSequence,
  };
}
