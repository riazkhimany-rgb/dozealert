import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/transit_catalog_bundled.dart';
import '../models/transit_catalog_manifest.dart';
import '../utils/app_branding.dart';
import '../utils/app_log.dart';

/// Outcome of a transit catalog refresh attempt.
enum TransitCatalogRefreshStatus {
  /// A newer, compatible catalog was fetched and applied.
  updated,

  /// The remote catalog matched (or was older than) the active catalog.
  upToDate,

  /// A newer catalog exists but requires a newer app version.
  incompatible,

  /// The remote catalog could not be fetched (offline, HTTP error, bad JSON).
  failed,
}

/// Result of a transit catalog refresh, with details for user messaging.
class TransitCatalogRefreshResult {
  const TransitCatalogRefreshResult(
    this.status, {
    this.catalogVersion,
    this.minAppVersion,
  });

  final TransitCatalogRefreshStatus status;
  final int? catalogVersion;
  final String? minAppVersion;

  bool get didUpdate => status == TransitCatalogRefreshStatus.updated;
}

/// Loads the versioned transit catalog from bundled JSON, on-device cache,
/// and the remote manifest on dozealert.app.
class TransitCatalogStore extends ChangeNotifier {
  TransitCatalogStore({
    http.Client? httpClient,
    this.remoteCatalogUrl =
        '${AppBranding.websiteUrl}/transit-catalog/transit-catalog.json',
    this.refreshInterval = const Duration(hours: 24),
  }) : _httpClient = httpClient ?? http.Client();

  static const _assetPath = 'assets/transit-catalog.json';
  static const _cacheJsonKey = 'transit_catalog_cache_json';
  static const _cacheVersionKey = 'transit_catalog_cache_version';
  static const _lastRefreshKey = 'transit_catalog_last_refresh_ms';

  final http.Client _httpClient;
  final String remoteCatalogUrl;
  final Duration refreshInterval;

  bool _initialized = false;
  bool _refreshing = false;
  TransitCatalogManifest? _activeManifest;

  bool get isInitialized => _initialized;

  /// Whether a refresh is currently in flight (for UI busy state).
  bool get isRefreshing => _refreshing;

  /// The active catalog version, or 0 before initialization.
  int get catalogVersion => _activeManifest?.catalogVersion ?? 0;

  TransitCatalogManifest get activeManifest {
    final manifest = _activeManifest;
    if (manifest == null) {
      throw StateError('TransitCatalogStore is not initialized.');
    }
    return manifest;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final candidates = <TransitCatalogManifest>[
      TransitCatalogBundled.manifest,
    ];
    final assetManifest = await _loadAssetManifest();
    if (assetManifest != null) {
      candidates.add(assetManifest);
    }
    final cachedManifest = await _loadCachedManifest();
    if (cachedManifest != null) {
      candidates.add(cachedManifest);
    }

    final appVersion = await _currentAppVersion();
    final manifest = _pickBestManifest(candidates, appVersion) ??
        TransitCatalogBundled.manifest;
    _applyManifest(manifest, notify: false);
    _initialized = true;
  }

  /// Fetches a newer remote catalog when the refresh interval has elapsed.
  ///
  /// Returns true only when a newer, compatible catalog was applied.
  Future<bool> refreshIfStale({bool force = false}) async {
    final result = await _refresh(force: force);
    return result.didUpdate;
  }

  /// User-initiated refresh that always contacts the remote catalog and
  /// returns a detailed [TransitCatalogRefreshResult] for messaging.
  Future<TransitCatalogRefreshResult> forceRefresh() async {
    if (_refreshing) {
      return const TransitCatalogRefreshResult(
        TransitCatalogRefreshStatus.failed,
      );
    }
    _refreshing = true;
    notifyListeners();
    try {
      return await _refresh(force: true);
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<TransitCatalogRefreshResult> _refresh({required bool force}) async {
    if (!_initialized) {
      await initialize();
    }

    final prefs = await SharedPreferences.getInstance();
    if (!force) {
      final lastRefresh = prefs.getInt(_lastRefreshKey);
      if (lastRefresh != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastRefresh;
        if (elapsed < refreshInterval.inMilliseconds) {
          return TransitCatalogRefreshResult(
            TransitCatalogRefreshStatus.upToDate,
            catalogVersion: catalogVersion,
          );
        }
      }
    }

    final remote = await _fetchRemoteManifest();
    if (remote == null) {
      return const TransitCatalogRefreshResult(
        TransitCatalogRefreshStatus.failed,
      );
    }

    await prefs.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);

    final currentVersion = _activeManifest?.catalogVersion ?? 0;
    if (remote.catalogVersion <= currentVersion) {
      return TransitCatalogRefreshResult(
        TransitCatalogRefreshStatus.upToDate,
        catalogVersion: currentVersion,
      );
    }

    final appVersion = await _currentAppVersion();
    if (!remote.isCompatibleWithApp(appVersion)) {
      AppLog.d(
        'TransitCatalogStore: ignored remote catalog v${remote.catalogVersion} '
        '(schema ${remote.schemaVersion}, min ${remote.minAppVersion})',
      );
      return TransitCatalogRefreshResult(
        TransitCatalogRefreshStatus.incompatible,
        catalogVersion: remote.catalogVersion,
        minAppVersion: remote.minAppVersion,
      );
    }

    await _cacheManifest(prefs, remote);
    _applyManifest(remote);
    AppLog.d(
      'TransitCatalogStore: updated catalog v${remote.catalogVersion} '
      '(${remote.agencies.length} agencies)',
    );
    return TransitCatalogRefreshResult(
      TransitCatalogRefreshStatus.updated,
      catalogVersion: remote.catalogVersion,
    );
  }

  Future<void> _cacheManifest(
    SharedPreferences prefs,
    TransitCatalogManifest manifest,
  ) async {
    await prefs.setString(
      _cacheJsonKey,
      jsonEncode(manifest.toCatalogJson()),
    );
    await prefs.setInt(_cacheVersionKey, manifest.catalogVersion);
  }

  void _applyManifest(TransitCatalogManifest manifest, {bool notify = true}) {
    _activeManifest = manifest;
    manifest.install();
    if (notify) {
      notifyListeners();
    }
  }

  Future<TransitCatalogManifest?> _loadAssetManifest() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      return TransitCatalogManifest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (error) {
      AppLog.d('TransitCatalogStore: bundled asset unavailable: $error');
      return null;
    }
  }

  Future<TransitCatalogManifest?> _loadCachedManifest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheJsonKey);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return TransitCatalogManifest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (error) {
      AppLog.d('TransitCatalogStore: cached catalog unreadable: $error');
      return null;
    }
  }

  Future<TransitCatalogManifest?> _fetchRemoteManifest() async {
    try {
      final response = await _httpClient
          .get(Uri.parse(remoteCatalogUrl))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        AppLog.d(
          'TransitCatalogStore: remote catalog HTTP ${response.statusCode}',
        );
        return null;
      }
      return TransitCatalogManifest.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (error) {
      AppLog.d('TransitCatalogStore: remote catalog fetch failed: $error');
      return null;
    }
  }

  Future<String> _currentAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  TransitCatalogManifest? _pickBestManifest(
    List<TransitCatalogManifest> candidates,
    String appVersion,
  ) {
    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (left, right) => right.catalogVersion.compareTo(left.catalogVersion),
    );

    for (final candidate in candidates) {
      if (candidate.schemaVersion >
          TransitCatalogManifest.supportedSchemaVersion) {
        continue;
      }
      if (!candidate.isCompatibleWithApp(appVersion)) {
        continue;
      }
      return candidate;
    }
    return null;
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }
}
