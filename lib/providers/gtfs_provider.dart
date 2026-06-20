import 'dart:async';

import 'package:flutter/material.dart';

import '../data/transit_catalog.dart';
import '../models/agency_detection_result.dart';
import '../models/destination.dart';
import '../models/transit_agency.dart';
import '../models/transit_stop.dart';
import '../models/transit_stop_search_result.dart';
import '../services/gtfs_import_service.dart';
import '../services/gtfs_service.dart';
import 'monitoring_provider.dart';
import 'transit_mode_provider.dart';
import 'transit_provider.dart';

class GtfsProvider extends ChangeNotifier {
  GtfsProvider(
    this._gtfsService,
    this._gtfsImportService,
    this._transitProvider,
    this._monitoringProvider,
    this._transitModeProvider,
  ) {
    _monitoringProvider.addListener(_handleDestinationChanged);
    _transitProvider.addListener(_handleTransitPreferencesChanged);
  }

  final GtfsService _gtfsService;
  final GtfsImportService _gtfsImportService;
  final TransitProvider _transitProvider;
  final MonitoringProvider _monitoringProvider;
  final TransitModeProvider _transitModeProvider;

  bool _initialized = false;
  AgencyDetectionResult? _lastDetection;

  bool get isInitialized => _initialized;
  AgencyDetectionResult? get lastDetection => _lastDetection;
  List<TransitAgency> get agencies => _gtfsService.agencies;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final cachedFeeds = await _gtfsImportService.loadCache();
    await _gtfsService.initializeFromFallbackData(cachedFeeds: cachedFeeds);
    _initialized = true;
    await _syncDefaultLineIfNeeded();
    notifyListeners();

    final destination = _monitoringProvider.selectedDestination;
    if (destination != null) {
      await detectAndApplyForDestination(destination);
    }
  }

  Future<void> refreshFromCache() async {
    final cachedFeeds = await _gtfsImportService.loadCache();
    await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
    _initialized = true;
    await _syncDefaultLineIfNeeded();
    notifyListeners();
  }

  Future<void> importZipFeed({
    required List<int> bytes,
    required String fileName,
    String? feedName,
  }) async {
    await _gtfsImportService.importZipBytes(
      bytes: bytes,
      fileName: fileName,
      feedName: feedName,
    );

    if (_initialized) {
      await _gtfsService.reinitialize(
        cachedFeeds: await _gtfsImportService.loadCache(),
      );
    }

    notifyListeners();
  }

  Future<void> refreshImportedFeeds() async {
    final cachedFeeds = await _gtfsImportService.refreshCache();
    if (_initialized) {
      await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
      notifyListeners();
    }
  }

  List<TransitStop> searchStops(String query) {
    if (!_initialized) {
      return const [];
    }
    return _gtfsService.searchStops(query);
  }

  List<TransitStopSearchResult> searchStopResults(String query) {
    if (!_initialized) {
      return const [];
    }
    return _gtfsService.searchStopResults(query);
  }

  bool hasStopsForSelectedLine() {
    if (!_initialized) {
      return false;
    }

    final preferences = _transitProvider.preferences;
    return _gtfsService.hasStopsForTransitLine(
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );
  }

  bool hasStopsForSelectedAgency() {
    if (!_initialized) {
      return false;
    }

    return _gtfsService.hasStopsForTransitSystem(
      _transitProvider.preferences.transitSystem,
    );
  }

  bool canShowStopPicker() {
    return hasStopsForSelectedLine() || hasStopsForSelectedAgency();
  }

  List<String> availableLinesForSelectedAgency() {
    if (!_initialized) {
      return const [];
    }

    return _gtfsService.linesForTransitSystem(
      _transitProvider.preferences.transitSystem,
    );
  }

  bool get usesDynamicLinesForSelectedAgency {
    final transitSystem = _transitProvider.preferences.transitSystem;
    return !TransitCatalog.hasCatalogLines(transitSystem);
  }

  List<TransitStopSearchResult> searchStopsForSelectedAgency(String query) {
    if (!_initialized) {
      return const [];
    }

    return _gtfsService.searchStopsForTransitSystem(
      _transitProvider.preferences.transitSystem,
      query,
    );
  }

  List<TransitStop> filterStopsForSelectedLine(String query) {
    if (!_initialized) {
      return const [];
    }

    final preferences = _transitProvider.preferences;
    final route = _gtfsService.routeForTransitLine(
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );
    if (route == null) {
      return const [];
    }

    return _gtfsService.filterStopsOnRoute(
      routeId: route.routeId,
      query: query,
    );
  }

  String get selectedLineLabel {
    final preferences = _transitProvider.preferences;
    return '${preferences.transitSystem} · ${preferences.defaultLine}';
  }

  AgencyDetectionResult? detectAgencyFromDestination(String destinationName) {
    return _gtfsService.detectAgencyFromDestination(destinationName);
  }

  Future<void> selectStop(TransitStop stop) async {
    _transitModeProvider.setActiveRouteId(stop.routeId);

    final route = _gtfsService.routeById(stop.routeId);
    if (route != null) {
      final agency = TransitCatalog.agencyByName(route.transitSystem);
      await _transitProvider.applyTransitSelection(
        country: route.country,
        region: agency?.region ??
            TransitCatalog.defaultRegionForCountry(route.country),
        transitSystem: route.transitSystem,
        defaultLine: route.lineName,
      );
    }

    final destination = Destination(
      name: stop.stopName,
      latitude: stop.latitude,
      longitude: stop.longitude,
    );

    await _monitoringProvider.setDestination(destination);
    await detectAndApplyForDestination(destination);
    notifyListeners();
  }

  Future<void> _syncDefaultLineIfNeeded() async {
    final preferences = _transitProvider.preferences;
    final lines = _gtfsService.linesForTransitSystem(preferences.transitSystem);
    if (lines.isEmpty) {
      return;
    }

    if (!lines.contains(preferences.defaultLine)) {
      await _transitProvider.setDefaultLine(lines.first);
    }
  }

  Future<void> detectAndApplyForDestination(Destination destination) async {
    if (!_initialized) {
      return;
    }

    final detection = _gtfsService.detectAgencyFromDestination(destination.name);
    _lastDetection = detection;
    if (detection == null) {
      notifyListeners();
      return;
    }

    final route = detection.route;
    if (route != null) {
      _transitModeProvider.setActiveRouteId(route.routeId);
      final agency = TransitCatalog.agencyByName(route.transitSystem);
      await _transitProvider.applyTransitSelection(
        country: route.country,
        region: agency?.region ??
            TransitCatalog.defaultRegionForCountry(route.country),
        transitSystem: route.transitSystem,
        defaultLine: route.lineName,
      );
    }

    notifyListeners();
  }

  void _handleTransitPreferencesChanged() {
    unawaited(_syncDefaultLineIfNeeded().then((_) => notifyListeners()));
  }

  void _handleDestinationChanged() {
    final destination = _monitoringProvider.selectedDestination;
    if (destination == null) {
      _lastDetection = null;
      notifyListeners();
      return;
    }

    unawaited(detectAndApplyForDestination(destination));
  }

  @override
  void dispose() {
    _monitoringProvider.removeListener(_handleDestinationChanged);
    _transitProvider.removeListener(_handleTransitPreferencesChanged);
    super.dispose();
  }
}
