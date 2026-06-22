import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/gtfs_feed_info.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import '../utils/app_log.dart';
import '../utils/gtfs_isolate_worker.dart';

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

  static bool get _useBackgroundIsolate {
    if (kIsWeb) {
      return false;
    }
    return Platform.environment['FLUTTER_TEST'] != 'true';
  }

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

    final encodeRequest = GtfsCacheEncodeRequest(
      feedInfoJson: info.toJson(),
      agenciesJson: agencies.map(agencyToJson).toList(growable: false),
      routesJson: routes.map(routeToJson).toList(growable: false),
      stopsJson: stops.map(stopToJson).toList(growable: false),
    );
    final encodedFiles = _useBackgroundIsolate
        ? await compute(encodeGtfsCacheFilesInIsolate, encodeRequest)
        : encodeGtfsCacheFilesInIsolate(encodeRequest);

    for (final entry in encodedFiles.entries) {
      await File('${feedDir.path}/${entry.key}').writeAsString(entry.value);
    }

    AppLog.d(
      'GtfsCacheStore: saved ${info.feedName} '
      '(${stops.length} stops, ${routes.length} routes)',
    );
  }

  Future<GtfsCachedFeed> loadFeed(String feedId) async {
    final cacheDir = await _resolveCacheDirectory();
    final feedDir = Directory('${cacheDir.path}/$feedId');
    if (_useBackgroundIsolate) {
      return compute(loadGtfsCachedFeedInIsolate, feedDir.path);
    }
    return loadGtfsCachedFeedInIsolate(feedDir.path);
  }

  Future<List<GtfsCachedFeed>> loadAllFeeds() async {
    try {
      final cacheDir = await _resolveCacheDirectory();
      if (!cacheDir.existsSync()) {
        return const [];
      }

      final feeds = _useBackgroundIsolate
          ? await compute(loadAllGtfsCachedFeedsInIsolate, cacheDir.path)
          : loadAllGtfsCachedFeedsInIsolate(cacheDir.path);
      AppLog.d('GtfsCacheStore: loaded ${feeds.length} cached feeds');
      return feeds;
    } catch (error) {
      AppLog.d('GtfsCacheStore: cache unavailable: $error');
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
      AppLog.d('GtfsCacheStore: deleted cached feed $feedId');
    }
  }
}
