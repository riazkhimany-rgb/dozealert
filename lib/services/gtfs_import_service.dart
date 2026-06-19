import 'package:flutter/foundation.dart';

import '../cache/gtfs_cache_store.dart';
import '../data/default_gtfs_feeds.dart';
import '../models/gtfs_feed_info.dart';
import '../models/transit_vehicle_type.dart';
import 'gtfs_parser_service.dart';

class GtfsImportService {
  GtfsImportService(this._cacheStore, this._parserService);

  final GtfsCacheStore _cacheStore;
  final GtfsParserService _parserService;

  static const supportedExamples = <String>[
    'GO Transit',
    'TTC',
    'York Region Transit',
    'Grand River Transit',
    'Brampton Transit',
    'Niagara Region Transit',
  ];

  Future<List<GtfsCachedFeed>> loadCache() {
    return _cacheStore.loadAllFeeds();
  }

  Future<List<GtfsFeedInfo>> loadFeedInfos() {
    return _cacheStore.loadFeedInfos();
  }

  Future<GtfsParseResult> importZipBytes({
    required List<int> bytes,
    required String fileName,
    String? feedName,
  }) async {
    final seed = _seedFeedForName(feedName ?? fileName.replaceAll('.zip', ''));
    final parsed = _parserService.parseZipBytes(
      bytes: bytes,
      fileName: fileName,
      seedFeed: seed,
    );

    await _cacheStore.saveFeed(
      info: parsed.feedInfo,
      agencies: parsed.agencies,
      routes: parsed.routes,
      stops: parsed.stops,
    );

    return parsed;
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

  GtfsFeedInfo _seedFeedForName(String name) {
    final byName = DefaultGtfsFeeds.byAgencyName(name);
    if (byName != null) {
      return byName;
    }

    final feedId = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final byId = DefaultGtfsFeeds.byId(feedId);
    if (byId != null) {
      return byId;
    }

    return GtfsFeedInfo(
      feedId: feedId,
      agencyName: name,
      province: 'Ontario',
      vehicleTypes: const [TransitVehicleType.bus],
    );
  }
}
