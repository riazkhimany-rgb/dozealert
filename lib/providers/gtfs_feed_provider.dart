import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../cache/gtfs_cache_store.dart';
import '../data/default_gtfs_feeds.dart';
import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../services/gtfs_download_service.dart';
import '../services/gtfs_import_service.dart';
import '../services/gtfs_parser_service.dart';
import '../services/gtfs_service.dart';
import '../utils/app_log.dart';
import '../utils/gtfs_isolate_worker.dart';

class GtfsFeedProgress {
  const GtfsFeedProgress({
    required this.phase,
    this.downloadFraction,
  });

  final String phase;
  final double? downloadFraction;
}

class GtfsFeedProvider extends ChangeNotifier {
  GtfsFeedProvider(
    this._downloadService,
    this._importService,
    this._cacheStore,
    this._gtfsService,
  );

  static const goTransitFeedId = 'go_transit';

  final GtfsDownloadService _downloadService;
  final GtfsImportService _importService;
  final GtfsCacheStore _cacheStore;
  final GtfsService _gtfsService;

  bool _initialized = false;
  List<GtfsFeedInfo> _feeds = const [];
  final Map<String, String?> _errors = {};
  final Map<String, GtfsFeedProgress> _progress = {};

  bool get isInitialized => _initialized;
  List<GtfsFeedInfo> get feeds => List.unmodifiable(_feeds);

  List<GtfsFeedInfo> feedsForRegion(String country, String region) {
    final feedIds = TransitCatalog.gtfsFeedsForRegion(country, region)
        .map((feed) => feed.feedId)
        .toSet();
    return _feeds
        .where((feed) => feedIds.contains(feed.feedId))
        .toList(growable: false);
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final cachedInfos = await _cacheStore.loadFeedInfos();
    _feeds = DefaultGtfsFeeds.feeds
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
    return DefaultGtfsFeeds.byId(feedId);
  }

  GtfsFeedInfo? feedForTransitSystem(String transitSystem) {
    final seed = DefaultGtfsFeeds.byAgencyName(transitSystem);
    if (seed == null) {
      return null;
    }
    return feedById(seed.feedId);
  }

  String? errorFor(String feedId) => _errors[feedId];

  GtfsFeedProgress? progressFor(String feedId) => _progress[feedId];

  bool isFeedBusy(String feedId) {
    final feed = feedById(feedId);
    if (feed == null) {
      return false;
    }
    return _progress.containsKey(feedId) ||
        feed.status == GtfsFeedStatus.downloading ||
        feed.status == GtfsFeedStatus.updating;
  }

  Future<void> downloadFeed(String feedId) async {
    await _fetchFeed(feedId, isUpdate: false);
  }

  /// Starts a background download when the feed is missing. Returns immediately.
  void preloadFeedIfNeeded(
    String feedId, {
    Future<void> Function()? onComplete,
  }) {
    if (!_initialized) {
      unawaited(_preloadAfterInitialize(feedId, onComplete: onComplete));
      return;
    }
    _startPreloadIfNeeded(feedId, onComplete: onComplete);
  }

  void preloadGoTransitIfNeeded({Future<void> Function()? onComplete}) {
    preloadFeedIfNeeded(goTransitFeedId, onComplete: onComplete);
  }

  Future<void> updateFeed(String feedId) async {
    await _fetchFeed(feedId, isUpdate: true);
  }

  Future<void> deleteFeed(String feedId) async {
    _errors.remove(feedId);
    _clearProgress(feedId);
    await _downloadService.deleteSavedFeed(feedId);
    await _cacheStore.deleteFeed(feedId);

    final cachedFeeds = await _cacheStore.loadAllFeeds();
    await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
    await _refreshFeedList();
    notifyListeners();
  }

  /// Removes every cached GTFS feed from device storage.
  Future<void> clearAllCachedFeeds() async {
    _errors.clear();
    _progress.clear();
    await _cacheStore.clearAllFeeds();
    await _gtfsService.reinitialize(cachedFeeds: const []);
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
    AppLog.d('GtfsFeedProvider: syncAllFeeds() is not implemented yet.');
  }

  Future<void> _preloadAfterInitialize(
    String feedId, {
    Future<void> Function()? onComplete,
  }) async {
    await initialize();
    _startPreloadIfNeeded(feedId, onComplete: onComplete);
  }

  void _startPreloadIfNeeded(
    String feedId, {
    Future<void> Function()? onComplete,
  }) {
    final feed = feedById(feedId);
    if (feed == null || feed.isDownloaded || isFeedBusy(feedId)) {
      return;
    }

    unawaited(_runPreload(feedId, onComplete: onComplete));
  }

  Future<void> _runPreload(
    String feedId, {
    Future<void> Function()? onComplete,
  }) async {
    try {
      await downloadFeed(feedId);
      if (onComplete != null) {
        await onComplete();
      }
    } catch (error) {
      AppLog.d('GtfsFeedProvider: preload failed for $feedId: $error');
    }
  }

  Future<void> _fetchFeed(String feedId, {required bool isUpdate}) async {
    final seed = DefaultGtfsFeeds.byId(feedId);
    if (seed == null) {
      throw ArgumentError('Unknown feed id: $feedId');
    }

    if (!seed.hasDirectDownload) {
      throw StateError(
        '${seed.agencyName} does not provide a direct GTFS download URL. '
        'Use the open data page and import the zip manually.',
      );
    }

    _errors.remove(feedId);
    _updateFeedStatus(
      feedId,
      isUpdate ? GtfsFeedStatus.updating : GtfsFeedStatus.downloading,
    );
    _setProgress(
      feedId,
      phase: isUpdate ? 'Preparing update…' : 'Starting download…',
    );
    await _yieldToUi();

    try {
      final bytes = await _downloadService.downloadFeed(
        seed.downloadUrl!,
        onProgress: (receivedBytes, totalBytes) {
          final fraction = totalBytes == null || totalBytes <= 0
              ? null
              : receivedBytes / totalBytes;
          _setProgress(
            feedId,
            phase: 'Downloading…',
            downloadFraction: fraction,
          );
        },
      );

      await _yieldToUi();
      _setProgress(feedId, phase: 'Processing GTFS data…');

      final parsed = await _parseFeedBytes(
        bytes: bytes,
        feedId: feedId,
        seed: seed,
      );

      await _yieldToUi();
      _setProgress(feedId, phase: 'Saving transit data…');

      await _downloadService.saveFeedZip(feedId: feedId, bytes: bytes);
      await _cacheStore.saveFeed(
        info: parsed.feedInfo,
        agencies: parsed.agencies,
        routes: parsed.routes,
        stops: parsed.stops,
      );

      await _yieldToUi();
      _setProgress(feedId, phase: 'Loading into app…');

      final cachedFeed = await _cacheStore.loadFeed(feedId);
      if (_gtfsService.isInitialized) {
        await _gtfsService.mergeCachedFeedAsync(cachedFeed);
      } else {
        final cachedFeeds = await _cacheStore.loadAllFeeds();
        await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
      }

      await _refreshFeedList();
    } catch (error) {
      _errors[feedId] = error.toString();
      _updateFeedStatus(feedId, GtfsFeedStatus.error, errorMessage: '$error');
      rethrow;
    } finally {
      _clearProgress(feedId);
      notifyListeners();
    }
  }

  Future<void> _refreshFeedList() async {
    final cachedInfos = await _cacheStore.loadFeedInfos();
    _feeds = DefaultGtfsFeeds.feeds
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

  void _setProgress(
    String feedId, {
    required String phase,
    double? downloadFraction,
  }) {
    _progress[feedId] = GtfsFeedProgress(
      phase: phase,
      downloadFraction: downloadFraction,
    );
    notifyListeners();
  }

  void _clearProgress(String feedId) {
    _progress.remove(feedId);
  }

  Future<void> _yieldToUi() async {
    await Future<void>.delayed(Duration.zero);
  }

  Future<GtfsParseResult> _parseFeedBytes({
    required List<int> bytes,
    required String feedId,
    required GtfsFeedInfo seed,
  }) async {
    final request = GtfsParseRequest(
      bytes: bytes,
      fileName: '$feedId.zip',
      seedFeedJson: seed.toJson(),
    );

    if (kIsWeb || Platform.environment['FLUTTER_TEST'] == 'true') {
      return parseGtfsZipInIsolate(request);
    }

    return compute(parseGtfsZipInIsolate, request);
  }
}
