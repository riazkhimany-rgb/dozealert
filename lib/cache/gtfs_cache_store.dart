import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/gtfs_feed_info.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import '../models/transit_vehicle_type.dart';

class GtfsCachedFeed {
  const GtfsCachedFeed({
    required this.info,
    required this.agencies,
    required this.routes,
    required this.stops,
  });

  final GtfsFeedInfo info;
  final List<TransitAgency> agencies;
  final List<TransitRoute> routes;
  final List<TransitStop> stops;
}

class GtfsCacheStore {
  static const _cacheFolderName = 'gtfs_cache';

  Directory? _cacheDirectory;

  Future<Directory> _resolveCacheDirectory() async {
    if (_cacheDirectory != null) {
      return _cacheDirectory!;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheFolderName');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    _cacheDirectory = cacheDir;
    return cacheDir;
  }

  Future<void> saveFeed({
    required GtfsFeedInfo info,
    required List<TransitAgency> agencies,
    required List<TransitRoute> routes,
    required List<TransitStop> stops,
  }) async {
    final cacheDir = await _resolveCacheDirectory();
    final feedDir = Directory('${cacheDir.path}/${info.feedId}');
    if (feedDir.existsSync()) {
      feedDir.deleteSync(recursive: true);
    }
    feedDir.createSync(recursive: true);

    await File('${feedDir.path}/feed_info.json').writeAsString(
      jsonEncode(info.toJson()),
    );
    await File('${feedDir.path}/agencies.json').writeAsString(
      jsonEncode(agencies.map(_agencyToJson).toList()),
    );
    await File('${feedDir.path}/routes.json').writeAsString(
      jsonEncode(routes.map(_routeToJson).toList()),
    );
    await File('${feedDir.path}/stops.json').writeAsString(
      jsonEncode(stops.map(_stopToJson).toList()),
    );

    debugPrint(
      'GtfsCacheStore: saved ${info.feedName} '
      '(${stops.length} stops, ${routes.length} routes)',
    );
  }

  Future<List<GtfsCachedFeed>> loadAllFeeds() async {
    try {
      final cacheDir = await _resolveCacheDirectory();
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
          final info = GtfsFeedInfo.fromJson(
            jsonDecode(await infoFile.readAsString()) as Map<String, dynamic>,
          );
          final agencies = _readAgencies('${entity.path}/agencies.json');
          final routes = _readRoutes('${entity.path}/routes.json');
          final stops = _readStops('${entity.path}/stops.json');
          feeds.add(
            GtfsCachedFeed(
              info: info,
              agencies: agencies,
              routes: routes,
              stops: stops,
            ),
          );
        } catch (error) {
          debugPrint('GtfsCacheStore: failed to load ${entity.path}: $error');
        }
      }

      feeds.sort((a, b) {
        final aDate =
            a.info.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.info.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      debugPrint('GtfsCacheStore: loaded ${feeds.length} cached feeds');
      return feeds;
    } catch (error) {
      debugPrint('GtfsCacheStore: cache unavailable: $error');
      return const [];
    }
  }

  Future<List<GtfsFeedInfo>> loadFeedInfos() async {
    final feeds = await loadAllFeeds();
    return feeds.map((feed) => feed.info).toList(growable: false);
  }

  Future<void> deleteFeed(String feedId) async {
    final cacheDir = await _resolveCacheDirectory();
    final feedDir = Directory('${cacheDir.path}/$feedId');
    if (feedDir.existsSync()) {
      feedDir.deleteSync(recursive: true);
      debugPrint('GtfsCacheStore: deleted cached feed $feedId');
    }
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

  Map<String, dynamic> _agencyToJson(TransitAgency agency) {
    return {
      'agencyId': agency.agencyId,
      'agencyName': agency.agencyName,
      'country': agency.country,
      'city': agency.city,
      'supportsRealtime': agency.supportsRealtime,
    };
  }

  Map<String, dynamic> _routeToJson(TransitRoute route) {
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

  Map<String, dynamic> _stopToJson(TransitStop stop) {
    return {
      'stopId': stop.stopId,
      'stopName': stop.stopName,
      'latitude': stop.latitude,
      'longitude': stop.longitude,
      'routeId': stop.routeId,
      'stopSequence': stop.stopSequence,
    };
  }
}
