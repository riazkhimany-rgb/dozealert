import 'dart:async';

import 'package:flutter/material.dart';

import '../data/transit_catalog.dart';
import '../models/agency_detection_result.dart';
import '../models/destination.dart';
import '../models/favorite_destination.dart';
import '../models/transit_line_option.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import '../models/transit_stop_search_result.dart';
import '../models/transit_vehicle_type.dart';
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

  String displayLabelForSelectedLine() {
    if (!_initialized) {
      return _transitProvider.preferences.defaultLine;
    }

    return _gtfsService.displayLabelForLine(
      _transitProvider.preferences.transitSystem,
      _transitProvider.preferences.defaultLine,
    );
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
    return _gtfsService.routeExistsForLineRef(
          transitSystem: transitSystem,
          lineRef: lineRef,
        ) ||
        TransitCatalog.isValidLineForSystem(transitSystem, lineRef);
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

  Future<void> selectStop(TransitStop stop) async {
    final destination = Destination(
      name: stop.stopName,
      latitude: stop.latitude,
      longitude: stop.longitude,
    );

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

  Future<void> selectDestinationWithTransit(Destination destination) async {
    await _monitoringProvider.setDestination(destination);
    await detectAndApplyForDestination(destination);
    notifyListeners();
  }

  Future<void> selectFavoriteDestination(FavoriteDestination item) async {
    final appliedFromSavedLine = await _applySavedTransitLine(item);

    _suppressDestinationDetection = true;
    try {
      await _monitoringProvider.setDestination(item.destination);
    } finally {
      _suppressDestinationDetection = false;
    }

    if (appliedFromSavedLine) {
      await syncTransitModeRouteForSelectedLine();
    } else {
      await detectAndApplyForDestination(item.destination);
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

  (String, String)? _transitLineFromBadges(List<String> badges) {
    for (final badge in badges) {
      final parsed = _parseTransitBadge(badge);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
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

    if (TransitCatalog.isValidLineForSystem(transitSystem, currentLine)) {
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
