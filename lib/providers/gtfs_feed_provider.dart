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
import '../utils/gtfs_cache_migration.dart';
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

  Future<void> Function()? onFeedsChanged;

  bool _initialized = false;
  bool _isUpgradingStaleFeeds = false;
  List<GtfsFeedInfo> _feeds = const [];
  final Map<String, String?> _errors = {};
  final Map<String, GtfsFeedProgress> _progress = {};

  bool get isInitialized => _initialized;
  bool get isUpgradingStaleFeeds => _isUpgradingStaleFeeds;
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

  /// Feeds whose cached stop data predates the current parse schema.
  Future<List<GtfsFeedInfo>> listStaleFeeds() async {
    final cachedFeeds = await _cacheStore.loadAllFeeds();
    final staleIds = cachedFeeds
        .where(GtfsCacheMigration.isStale)
        .map((feed) => feed.info.feedId)
        .toSet();
    if (staleIds.isEmpty) {
      return const [];
    }
    return _feeds
        .where((feed) => staleIds.contains(feed.feedId))
        .toList(growable: false);
  }

  /// Re-parses or re-downloads cached feeds that predate direction-aware parsing.
  ///
  /// Returns feed ids queued for a background download (no saved zip available).
  Future<Set<String>> upgradeStaleFeedsIfNeeded({
    void Function({
      required String feedId,
      required String agencyName,
      required String progressPhase,
      required int completedFeeds,
      required int totalFeeds,
    })? onProgress,
  }) async {
    final cachedFeeds = await _cacheStore.loadAllFeeds();
    final staleFeeds = cachedFeeds.where(GtfsCacheMigration.isStale).toList();
    if (staleFeeds.isEmpty) {
      return const {};
    }

    _isUpgradingStaleFeeds = true;
    notifyListeners();

    AppLog.d(
      'GtfsFeedProvider: upgrading ${staleFeeds.length} stale GTFS feed(s)',
    );

    final queuedDownloads = <String>{};
    var completed = 0;
    final total = staleFeeds.length;

    for (final feed in staleFeeds) {
      final feedId = feed.info.feedId;
      final agencyName = feed.info.agencyName;
      onProgress?.call(
        feedId: feedId,
        agencyName: agencyName,
        progressPhase: 'Reading saved data…',
        completedFeeds: completed,
        totalFeeds: total,
      );

      final reparsed = await _tryReparseSavedZip(feedId);
      if (reparsed) {
        AppLog.d('GtfsFeedProvider: reparsed stale feed $feedId from saved zip');
        completed++;
        onProgress?.call(
          feedId: feedId,
          agencyName: agencyName,
          progressPhase: 'Done',
          completedFeeds: completed,
          totalFeeds: total,
        );
        continue;
      }

      await _cacheStore.deleteFeed(feedId);
      await _downloadService.deleteSavedFeed(feedId);

      final seed = DefaultGtfsFeeds.byId(feedId) ?? feed.info;
      if (seed.hasDirectDownload) {
        queuedDownloads.add(feedId);
        AppLog.d('GtfsFeedProvider: queued re-download for stale feed $feedId');
      } else {
        AppLog.d(
          'GtfsFeedProvider: removed stale manual-import feed $feedId '
          '(re-import required)',
        );
      }
      completed++;
      onProgress?.call(
        feedId: feedId,
        agencyName: agencyName,
        progressPhase: seed.hasDirectDownload
            ? 'Queued for download'
            : 'Needs re-import',
        completedFeeds: completed,
        totalFeeds: total,
      );
    }

    await _refreshFeedList();
    _isUpgradingStaleFeeds = false;
    notifyListeners();
    await _notifyFeedsChanged();
    return queuedDownloads;
  }

  void queueBackgroundDownloads(
    Iterable<String> feedIds, {
    @Deprecated('Use GtfsFeedProvider.onFeedsChanged instead')
    Future<void> Function()? onEachComplete,
  }) {
    for (final feedId in feedIds) {
      if (isFeedBusy(feedId)) {
        continue;
      }
      unawaited(_runPreload(feedId));
    }
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

  void preloadForTransitSystemIfNeeded(
    String transitSystem, {
    Future<void> Function()? onComplete,
  }) {
    final feed = feedForTransitSystem(transitSystem);
    if (feed == null || !feed.hasDirectDownload) {
      return;
    }
    preloadFeedIfNeeded(feed.feedId, onComplete: onComplete);
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
    await _notifyFeedsChanged();
  }

  /// Removes every cached GTFS feed from device storage.
  Future<void> clearAllCachedFeeds() async {
    _errors.clear();
    _progress.clear();
    await _cacheStore.clearAllFeeds();
    await _gtfsService.reinitialize(cachedFeeds: const []);
    await _refreshFeedList();
    notifyListeners();
    await _notifyFeedsChanged();
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
    await _notifyFeedsChanged();
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
        shapes: parsed.shapes,
      );

      await _yieldToUi();
      _setProgress(feedId, phase: 'Loading into app…');

      await _mergeCachedFeedFromDisk(feedId);

      await _refreshFeedList();
      await _notifyFeedsChanged();
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

  Future<void> _mergeCachedFeedFromDisk(String feedId) async {
    final cachedFeed = await _cacheStore.loadFeed(feedId);
    if (_gtfsService.isInitialized) {
      await _gtfsService.mergeCachedFeedAsync(cachedFeed);
      return;
    }

    final cachedFeeds = await _cacheStore.loadAllFeeds();
    await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
  }

  Future<void> _notifyFeedsChanged() async {
    final callback = onFeedsChanged;
    if (callback == null) {
      return;
    }
    await callback();
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

  Future<bool> _tryReparseSavedZip(String feedId) async {
    final seed = DefaultGtfsFeeds.byId(feedId);
    if (seed == null) {
      return false;
    }

    final bytes = await _downloadService.readSavedFeedZip(feedId);
    if (bytes == null || bytes.isEmpty) {
      return false;
    }

    try {
      final parsed = await _parseFeedBytes(
        bytes: bytes,
        feedId: feedId,
        seed: seed,
      );
      await _cacheStore.saveFeed(
        info: parsed.feedInfo,
        agencies: parsed.agencies,
        routes: parsed.routes,
        stops: parsed.stops,
        shapes: parsed.shapes,
      );

      await _mergeCachedFeedFromDisk(feedId);
      return true;
    } catch (error) {
      AppLog.d('GtfsFeedProvider: reparse failed for $feedId: $error');
      return false;
    }
  }
}
