import 'package:flutter/foundation.dart';

import '../cache/gtfs_cache_store.dart';
import '../data/predefined_gtfs_feeds.dart';
import '../models/gtfs_feed_info.dart';
import '../services/gtfs_download_service.dart';
import '../services/gtfs_import_service.dart';
import '../services/gtfs_parser_service.dart';
import '../services/gtfs_service.dart';

class GtfsFeedProvider extends ChangeNotifier {
  GtfsFeedProvider(
    this._downloadService,
    this._parserService,
    this._importService,
    this._cacheStore,
    this._gtfsService,
  );

  final GtfsDownloadService _downloadService;
  final GtfsParserService _parserService;
  final GtfsImportService _importService;
  final GtfsCacheStore _cacheStore;
  final GtfsService _gtfsService;

  bool _initialized = false;
  List<GtfsFeedInfo> _feeds = const [];
  final Map<String, String?> _errors = {};

  bool get isInitialized => _initialized;
  List<GtfsFeedInfo> get feeds => List.unmodifiable(_feeds);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final cachedInfos = await _cacheStore.loadFeedInfos();
    _feeds = PredefinedGtfsFeeds.feeds
        .map((seed) => _mergeSeedWithCache(seed, cachedInfos))
        .toList(growable: false);
    _initialized = true;
    notifyListeners();
  }

  GtfsFeedInfo? feedById(String feedId) {
    for (final feed in _feeds) {
      if (feed.feedId == feedId) {
        return feed;
      }
    }
    return PredefinedGtfsFeeds.byId(feedId);
  }

  String? errorFor(String feedId) => _errors[feedId];

  Future<void> downloadFeed(String feedId) async {
    await _fetchFeed(feedId, isUpdate: false);
  }

  Future<void> updateFeed(String feedId) async {
    await _fetchFeed(feedId, isUpdate: true);
  }

  Future<void> deleteFeed(String feedId) async {
    _errors.remove(feedId);
    await _downloadService.deleteSavedFeed(feedId);
    await _cacheStore.deleteFeed(feedId);

    final cachedFeeds = await _cacheStore.loadAllFeeds();
    await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
    await _refreshFeedList();
    notifyListeners();
  }

  Future<void> importZipBytes({
    required List<int> bytes,
    required String fileName,
    String? feedName,
  }) async {
    await _importService.importZipBytes(
      bytes: bytes,
      fileName: fileName,
      feedName: feedName,
    );

    final cachedFeeds = await _cacheStore.loadAllFeeds();
    await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
    await _refreshFeedList();
    notifyListeners();
  }

  Future<void> syncAllFeeds() async {
    debugPrint('GtfsFeedProvider: syncAllFeeds() is not implemented yet.');
  }

  Future<void> _fetchFeed(String feedId, {required bool isUpdate}) async {
    final seed = PredefinedGtfsFeeds.byId(feedId);
    if (seed == null) {
      throw ArgumentError('Unknown feed id: $feedId');
    }

    final downloadUrl = seed.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      throw StateError('No download URL configured for ${seed.agencyName}.');
    }

    _errors.remove(feedId);
    _updateFeedStatus(
      feedId,
      isUpdate ? GtfsFeedStatus.updating : GtfsFeedStatus.downloading,
    );

    try {
      final bytes = await _downloadService.downloadFeed(downloadUrl);
      await _downloadService.saveFeedZip(feedId: feedId, bytes: bytes);

      final parsed = _parserService.parseZipBytes(
        bytes: bytes,
        fileName: '$feedId.zip',
        seedFeed: seed,
      );

      await _cacheStore.saveFeed(
        info: parsed.feedInfo,
        agencies: parsed.agencies,
        routes: parsed.routes,
        stops: parsed.stops,
      );

      final cachedFeeds = await _cacheStore.loadAllFeeds();
      await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
      await _refreshFeedList();
    } catch (error) {
      _errors[feedId] = error.toString();
      _updateFeedStatus(feedId, GtfsFeedStatus.error, errorMessage: '$error');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _refreshFeedList() async {
    final cachedInfos = await _cacheStore.loadFeedInfos();
    _feeds = PredefinedGtfsFeeds.feeds
        .map((seed) => _mergeSeedWithCache(seed, cachedInfos))
        .toList(growable: false);
  }

  GtfsFeedInfo _mergeSeedWithCache(
    GtfsFeedInfo seed,
    List<GtfsFeedInfo> cachedInfos,
  ) {
    for (final cached in cachedInfos) {
      if (cached.feedId == seed.feedId) {
        return seed.copyWith(
          agencyCount: cached.agencyCount,
          routeCount: cached.routeCount,
          stopCount: cached.stopCount,
          lastUpdated: cached.lastUpdated,
          sourceFileName: cached.sourceFileName,
          status: GtfsFeedStatus.downloaded,
        );
      }
    }
    return seed;
  }

  void _updateFeedStatus(
    String feedId,
    GtfsFeedStatus status, {
    String? errorMessage,
  }) {
    _feeds = _feeds
        .map(
          (feed) => feed.feedId == feedId
              ? feed.copyWith(status: status, errorMessage: errorMessage)
              : feed,
        )
        .toList(growable: false);
    notifyListeners();
  }
}
