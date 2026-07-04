import 'dart:async';

import 'package:flutter/material.dart';

import '../data/transit_catalog.dart';
import '../models/agency_detection_result.dart';
import '../models/destination.dart';
import '../models/favorite_destination.dart';
import '../models/favorite_transit_line.dart';
import '../models/gtfs_station.dart';
import '../models/gtfs_station_search_result.dart';
import '../models/transit_line_option.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import '../models/transit_stop_search_result.dart';
import '../models/transit_vehicle_type.dart';
import '../utils/gtfs_stop_name_utils.dart';
import '../utils/gtfs_station_utils.dart';
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
  bool _suppressDestinationDetection = false;

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

  Future<void> notifyDataUpdated() async {
    if (!_initialized) {
      return;
    }
    await _syncDefaultLineIfNeeded();
    notifyListeners();
  }

  Future<void> refreshFromCache() async {
    final cachedFeeds = await _gtfsImportService.loadCache();
    await _gtfsService.reinitialize(cachedFeeds: cachedFeeds);
    _initialized = true;
    await _syncDefaultLineIfNeeded();
    notifyListeners();
  }

  Future<void> onFeedDataChanged() async {
    await refreshFromCache();
    await notifyDataUpdated();
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
    return hasStopsForLine(
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );
  }

  bool hasStopsForLine({
    required String transitSystem,
    required String lineName,
  }) {
    if (!_initialized) {
      return false;
    }

    return _gtfsService.hasStopsForTransitLine(
      transitSystem: transitSystem,
      lineName: lineName,
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

  List<String> availableLinesForSelectedAgency({
    TransitVehicleType? vehicleType,
  }) {
    return availableLineOptionsForSelectedAgency(vehicleType: vehicleType)
        .map((option) => option.lineName)
        .toList(growable: false);
  }

  List<TransitLineOption> availableLineOptionsForSelectedAgency({
    TransitVehicleType? vehicleType,
  }) {
    return lineOptionsForAgency(
      _transitProvider.preferences.transitSystem,
      vehicleType: vehicleType,
    );
  }

  List<TransitLineOption> lineOptionsForAgency(
    String transitSystem, {
    TransitVehicleType? vehicleType,
  }) {
    if (!_initialized) {
      return const [];
    }

    return _gtfsService.lineOptionsForTransitSystem(
      transitSystem,
      vehicleType: vehicleType,
    );
  }

  List<TransitVehicleType> vehicleTypesForAgency(String transitSystem) {
    if (!_initialized) {
      return const [];
    }

    return _gtfsService.vehicleTypesForTransitSystem(transitSystem);
  }

  /// First selectable line for [transitSystem], preferring GTFS routes when loaded.
  String defaultLineForAgency(String transitSystem) {
    if (_initialized) {
      final lines = _gtfsService.linesForTransitSystem(transitSystem);
      if (lines.isNotEmpty) {
        return lines.first;
      }
    }

    return TransitCatalog.defaultLineForSystem(transitSystem);
  }

  /// Human-readable favorite label (agency + full line name) resolved from
  /// loaded GTFS routes. Falls back to the favorite's stored label when GTFS
  /// is not yet available.
  String favoriteLineLabel(FavoriteTransitLine favorite) {
    if (_initialized) {
      return _gtfsService.favoriteLineLabel(
        transitSystem: favorite.transitSystem,
        lineName: favorite.lineName,
      );
    }
    return favorite.label;
  }

  String displayLabelForSelectedLine() {
    if (!_initialized) {
      return _transitProvider.preferences.defaultLine;
    }

    return _gtfsService.displayLabelForLine(
      _transitProvider.preferences.transitSystem,
      _transitProvider.preferences.defaultLine,
    );
  }

  /// Returns the [TransitLineOption.lineName] from [options] that matches
  /// [lineRef], including long names and route codes stored in preferences.
  String? resolveLineNameInOptions(
    String lineRef,
    List<TransitLineOption> options,
  ) {
    if (lineRef.trim().isEmpty || options.isEmpty) {
      return null;
    }

    for (final option in options) {
      if (option.lineName == lineRef) {
        return option.lineName;
      }
    }

    if (!_initialized) {
      return null;
    }

    final resolved = _gtfsService.resolvePreferenceLineName(
      transitSystem: _transitProvider.preferences.transitSystem,
      lineRef: lineRef,
    );
    if (resolved != null &&
        options.any((option) => option.lineName == resolved)) {
      return resolved;
    }

    return null;
  }

  TransitLineOption? lineOptionForPreference(
    String lineRef,
    List<TransitLineOption> options,
  ) {
    final resolved = resolveLineNameInOptions(lineRef, options);
    if (resolved == null) {
      return null;
    }

    for (final option in options) {
      if (option.lineName == resolved) {
        return option;
      }
    }
    return null;
  }

  List<TransitVehicleType> availableVehicleTypesForSelectedAgency() {
    if (!_initialized) {
      return const [];
    }

    return _gtfsService.vehicleTypesForTransitSystem(
      _transitProvider.preferences.transitSystem,
    );
  }

  /// Whether [lineRef] resolves to a real route for the selected agency, or is
  /// a valid catalog line. Mirrors the rules used by [_syncDefaultLineIfNeeded]
  /// so UI can avoid clobbering a still-valid line selection.
  bool selectedAgencyHasRouteForLine(String lineRef) {
    if (!_initialized || lineRef.trim().isEmpty) {
      return false;
    }

    final transitSystem = _transitProvider.preferences.transitSystem;
    if (_gtfsService.routeExistsForLineRef(
      transitSystem: transitSystem,
      lineRef: lineRef,
    )) {
      return true;
    }

    if (_gtfsService.hasGtfsRoutesForTransitSystem(transitSystem)) {
      return false;
    }

    return TransitCatalog.isValidLineForSystem(transitSystem, lineRef);
  }

  bool get usesDynamicLinesForSelectedAgency {
    if (!_initialized) {
      return false;
    }

    return _gtfsService.hasGtfsRoutesForTransitSystem(
      _transitProvider.preferences.transitSystem,
    );
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

  List<GtfsStationSearchResult> searchStationsForSelectedAgency(String query) {
    if (!_initialized) {
      return const [];
    }

    return _gtfsService.searchStationsForTransitSystem(
      _transitProvider.preferences.transitSystem,
      query,
    );
  }

  List<GtfsStation> filterStationsForSelectedLine(String query) {
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

    return _gtfsService.filterStationsOnRoute(
      routeId: route.routeId,
      query: query,
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
    if (!_initialized) {
      return '${preferences.transitSystem} · ${preferences.defaultLine}';
    }

    return _gtfsService.selectedLineDisplayLabel(
      transitSystem: preferences.transitSystem,
      lineRef: preferences.defaultLine,
    );
  }

  Future<void> syncTransitModeRouteForSelectedLine() async {
    if (!_initialized) {
      return;
    }

    final preferences = _transitProvider.preferences;
    final route = _gtfsService.routeForTransitLine(
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );
    if (route != null) {
      _transitModeProvider.setActiveRouteId(route.routeId);
    }
    notifyListeners();
  }

  AgencyDetectionResult? detectAgencyFromDestination(String destinationName) {
    return _gtfsService.detectAgencyFromDestination(destinationName);
  }

  Destination enrichDestination(Destination destination) {
    final displayName = GtfsStopNameUtils.stationDisplayName(destination.name);
    final stationKey = destination.stationKey ??
        GtfsStationUtils.stationKey(
          displayName,
          destination.latitude,
          destination.longitude,
        );
    if (displayName == destination.name && stationKey == destination.stationKey) {
      return destination;
    }
    return destination.copyWith(name: displayName, stationKey: stationKey);
  }

  Future<void> selectStation(GtfsStation station) async {
    final destination = enrichDestination(
      Destination(
        name: station.name,
        latitude: station.latitude,
        longitude: station.longitude,
        stationKey: station.stationKey,
      ),
    );

    final stop = station.representativeStop;
    final selectedRoute = _selectedRoute();
    if (selectedRoute != null && stop.routeId == selectedRoute.routeId) {
      _transitModeProvider.setActiveRouteId(selectedRoute.routeId);
      _suppressDestinationDetection = true;
      try {
        await _monitoringProvider.setDestination(destination);
      } finally {
        _suppressDestinationDetection = false;
      }
      notifyListeners();
      return;
    }

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

    _suppressDestinationDetection = true;
    try {
      await _monitoringProvider.setDestination(destination);
    } finally {
      _suppressDestinationDetection = false;
    }
    notifyListeners();
  }

  Future<void> selectStop(TransitStop stop) async {
    await selectStation(_gtfsService.stationFromStop(stop));
  }

  Future<void> selectDestinationWithTransit(Destination destination) async {
    final enriched = enrichDestination(destination);
    await _monitoringProvider.setDestination(enriched);
    await detectAndApplyForDestination(enriched);
    notifyListeners();
  }

  Future<void> selectFavoriteDestination(FavoriteDestination item) async {
    final appliedFromSavedLine = await _applySavedTransitLine(item);
    final enriched = enrichDestination(item.destination);

    _suppressDestinationDetection = true;
    try {
      await _monitoringProvider.setDestination(enriched);
    } finally {
      _suppressDestinationDetection = false;
    }

    if (appliedFromSavedLine) {
      await syncTransitModeRouteForSelectedLine();
    } else {
      await detectAndApplyForDestination(enriched);
    }
    notifyListeners();
  }

  FavoriteDestination buildFavoriteDestination(
    Destination destination, {
    TransitStop? stop,
  }) {
    final transit = _savedTransitInfoForDestination(
      destination,
      stop: stop,
    );
    if (transit != null) {
      return FavoriteDestination(
        destination: destination,
        badges: [transit.badge],
        transitSystem: transit.transitSystem,
        lineName: transit.lineName,
      );
    }

    final preferences = _transitProvider.preferences;
    return FavoriteDestination(
      destination: destination,
      badges: [
        '${preferences.transitSystem} · ${preferences.defaultLine}',
      ],
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );
  }

  ({String badge, String lineName, String transitSystem})?
      _savedTransitInfoForDestination(
    Destination destination, {
    TransitStop? stop,
  }) {
    if (stop != null) {
      final route = _gtfsService.routeById(stop.routeId);
      if (route != null) {
        final info = _gtfsService.transitLineInfoForRoute(route);
        return (
          badge: info.badge,
          lineName: info.lineName,
          transitSystem: route.transitSystem,
        );
      }
    }

    if (_initialized) {
      final selectedRoute = _selectedRoute();
      if (selectedRoute != null) {
        final onSelectedRoute = _gtfsService.detectDestinationOnRoute(
          destinationName: destination.name,
          routeId: selectedRoute.routeId,
          latitude: destination.latitude,
          longitude: destination.longitude,
        );
        final route = onSelectedRoute?.route;
        if (route != null) {
          final info = _gtfsService.transitLineInfoForRoute(route);
          return (
            badge: info.badge,
            lineName: info.lineName,
            transitSystem: route.transitSystem,
          );
        }
      }

      final detection = _gtfsService.detectAgencyFromDestinationAt(
        destinationName: destination.name,
        latitude: destination.latitude,
        longitude: destination.longitude,
      );
      final route = detection?.route;
      if (route != null) {
        final info = _gtfsService.transitLineInfoForRoute(route);
        return (
          badge: info.badge,
          lineName: info.lineName,
          transitSystem: route.transitSystem,
        );
      }
    }

    return null;
  }

  String? transitBadgeForStop(TransitStop stop) {
    return _gtfsService.transitBadgeForStop(stop);
  }

  List<String> favoriteBadgesForDestination(
    Destination destination, {
    TransitStop? stop,
  }) {
    if (stop != null) {
      final badge = transitBadgeForStop(stop);
      return badge == null ? const [] : [badge];
    }

    if (_initialized) {
      final selectedRoute = _selectedRoute();
      if (selectedRoute != null) {
        final onSelectedRoute = _gtfsService.detectDestinationOnRoute(
          destinationName: destination.name,
          routeId: selectedRoute.routeId,
          latitude: destination.latitude,
          longitude: destination.longitude,
        );
        final route = onSelectedRoute?.route;
        if (route != null) {
          return [_gtfsService.transitLineInfoForRoute(route).badge];
        }
      }

      final detection = _gtfsService.detectAgencyFromDestinationAt(
        destinationName: destination.name,
        latitude: destination.latitude,
        longitude: destination.longitude,
      );
      final route = detection?.route;
      if (route != null) {
        return [_gtfsService.transitLineInfoForRoute(route).badge];
      }
    }

    final preferences = _transitProvider.preferences;
    return ['${preferences.transitSystem} · ${preferences.defaultLine}'];
  }

  Future<bool> _applySavedTransitLine(FavoriteDestination item) async {
    final saved = item.savedTransitLine;
    if (saved != null) {
      return _applyTransitLine(
        transitSystem: saved.transitSystem,
        lineName: saved.lineName,
      );
    }

    return _applyTransitFromFavoriteBadges(item);
  }

  Future<bool> _applyTransitLine({
    required String transitSystem,
    required String lineName,
  }) async {
    final agency = TransitCatalog.agencyByName(transitSystem);
    if (agency == null) {
      return false;
    }

    await _transitProvider.applyTransitSelection(
      country: agency.country,
      region: agency.region,
      transitSystem: transitSystem,
      defaultLine: lineName,
    );
    await syncTransitModeRouteForSelectedLine();
    return true;
  }

  Future<bool> _applyTransitFromFavoriteBadges(
    FavoriteDestination item,
  ) async {
    final saved = item.savedTransitLine;
    if (saved != null) {
      return _applyTransitLine(
        transitSystem: saved.transitSystem,
        lineName: saved.lineName,
      );
    }

    for (final badge in item.badges) {
      final parsed = _parseTransitBadge(badge);
      if (parsed == null) {
        continue;
      }

      final agency = TransitCatalog.agencyByName(parsed.$1);
      if (agency == null) {
        continue;
      }

      await _transitProvider.applyTransitSelection(
        country: agency.country,
        region: agency.region,
        transitSystem: parsed.$1,
        defaultLine: parsed.$2,
      );
      await syncTransitModeRouteForSelectedLine();
      return true;
    }

    return false;
  }

  (String, String)? _parseTransitBadge(String badge) {
    final parts = badge.split(' · ');
    if (parts.length != 2) {
      return null;
    }

    final transitSystem = parts[0].trim();
    final lineName = parts[1].trim();
    if (transitSystem.isEmpty || lineName.isEmpty) {
      return null;
    }

    if (TransitCatalog.agencyByName(transitSystem) == null) {
      return null;
    }

    return (transitSystem, lineName);
  }

  Future<void> _syncDefaultLineIfNeeded() async {
    final preferences = _transitProvider.preferences;
    final transitSystem = preferences.transitSystem;
    final lines = _gtfsService.linesForTransitSystem(transitSystem);
    if (lines.isEmpty) {
      return;
    }

    final currentLine = preferences.defaultLine;
    if (lines.contains(currentLine)) {
      return;
    }

    if (_gtfsService.routeExistsForLineRef(
      transitSystem: transitSystem,
      lineRef: currentLine,
    )) {
      return;
    }

    if (!_gtfsService.hasGtfsRoutesForTransitSystem(transitSystem) &&
        TransitCatalog.isValidLineForSystem(transitSystem, currentLine)) {
      return;
    }

    await _transitProvider.setDefaultLine(lines.first);
  }

  Future<void> detectAndApplyForDestination(Destination destination) async {
    if (!_initialized) {
      return;
    }

    if (_monitoringProvider.selectedDestination == null) {
      notifyListeners();
      return;
    }

    final current = _monitoringProvider.selectedDestination!;
    if (current.name != destination.name ||
        current.latitude != destination.latitude ||
        current.longitude != destination.longitude) {
      return;
    }

    final selectedRoute = _selectedRoute();
    if (selectedRoute != null) {
      final onSelectedRoute = _gtfsService.detectDestinationOnRoute(
        destinationName: destination.name,
        routeId: selectedRoute.routeId,
        latitude: destination.latitude,
        longitude: destination.longitude,
      );
      if (onSelectedRoute != null) {
        _lastDetection = onSelectedRoute;
        _transitModeProvider.setActiveRouteId(selectedRoute.routeId);
        notifyListeners();
        return;
      }
    }

    final detection = _gtfsService.detectAgencyFromDestinationAt(
      destinationName: destination.name,
      latitude: destination.latitude,
      longitude: destination.longitude,
    );
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

  TransitRoute? _selectedRoute() {
    if (!_initialized) {
      return null;
    }

    final preferences = _transitProvider.preferences;
    return _gtfsService.routeForTransitLine(
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );
  }

  void _handleTransitPreferencesChanged() {
    unawaited(_syncDefaultLineIfNeeded().then((_) => notifyListeners()));
  }

  void _handleDestinationChanged() {
    final destination = _monitoringProvider.selectedDestination;
    if (destination == null) {
      _lastDetection = null;
      unawaited(syncTransitModeRouteForSelectedLine());
      notifyListeners();
      return;
    }

    if (_suppressDestinationDetection) {
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
