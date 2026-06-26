import 'package:geolocator/geolocator.dart';

import '../cache/gtfs_cache_store.dart';
import '../data/transit_catalog.dart';
import '../models/agency_detection_result.dart';
import '../models/transit_agency.dart';
import '../models/transit_line_option.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import '../models/transit_stop_search_result.dart';
import '../models/transit_vehicle_type.dart';
import 'transit_data_service.dart';
import '../utils/app_log.dart';

class GtfsService {
  GtfsService(this._transitDataService);

  final TransitDataService _transitDataService;

  bool _initialized = false;
  final List<TransitAgency> _agencies = [];
  final List<TransitRoute> _routes = [];
  final List<TransitStop> _stops = [];
  final Map<String, TransitAgency> _agenciesById = {};
  final Map<String, TransitRoute> _routesById = {};
  final Map<String, List<TransitStop>> _stopsByRouteId = {};

  List<TransitAgency> get agencies => List.unmodifiable(_agencies);
  List<TransitRoute> get routes => List.unmodifiable(_routes);
  List<TransitStop> get stops => List.unmodifiable(_stops);
  bool get isInitialized => _initialized;

  static List<TransitAgency> get seededAgencies => TransitCatalog.seedAgencies;

  Future<void> initializeFromFallbackData({
    List<GtfsCachedFeed> cachedFeeds = const [],
  }) async {
    if (_initialized) {
      return;
    }

    _agencies
      ..clear()
      ..addAll(seededAgencies);

    _routes.clear();
    _stops.clear();
    _agenciesById.clear();
    _routesById.clear();
    _stopsByRouteId.clear();

    for (final agency in _agencies) {
      _agenciesById[agency.agencyId] = agency;
    }

    for (final feed in cachedFeeds) {
      mergeCachedFeed(feed);
    }

    _initialized = true;
    AppLog.d(
      'GtfsService: initialized ${_stops.length} stops across ${_routes.length} routes',
    );
  }

  void mergeCachedFeed(GtfsCachedFeed feed) {
    final transitSystems =
        feed.routes.map((route) => route.transitSystem).toSet();
    for (final transitSystem in transitSystems) {
      _removeTransitSystemData(transitSystem);
    }

    for (final agency in feed.agencies) {
      _agenciesById[agency.agencyId] = agency;
      if (!_agencies.any((entry) => entry.agencyId == agency.agencyId)) {
        _agencies.add(agency);
      }
    }

    for (final route in feed.routes) {
      _routesById[route.routeId] = route;
      if (!_routes.any((entry) => entry.routeId == route.routeId)) {
        _routes.add(route);
      }
      _stopsByRouteId.putIfAbsent(route.routeId, () => []);
    }

    for (final stop in feed.stops) {
      _mergeStop(stop);
    }

    AppLog.d(
      'GtfsService: merged cached feed ${feed.info.feedName} '
      '(${feed.stops.length} stops)',
    );
  }

  Future<void> mergeCachedFeedAsync(GtfsCachedFeed feed) async {
    final transitSystems =
        feed.routes.map((route) => route.transitSystem).toSet();
    for (final transitSystem in transitSystems) {
      _removeTransitSystemData(transitSystem);
    }

    for (final agency in feed.agencies) {
      _agenciesById[agency.agencyId] = agency;
      if (!_agencies.any((entry) => entry.agencyId == agency.agencyId)) {
        _agencies.add(agency);
      }
    }

    for (final route in feed.routes) {
      _routesById[route.routeId] = route;
      if (!_routes.any((entry) => entry.routeId == route.routeId)) {
        _routes.add(route);
      }
      _stopsByRouteId.putIfAbsent(route.routeId, () => []);
    }

    var processed = 0;
    for (final stop in feed.stops) {
      _mergeStop(stop);
      processed++;
      if (processed % 1000 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    AppLog.d(
      'GtfsService: merged cached feed ${feed.info.feedName} '
      '(${feed.stops.length} stops)',
    );
  }

  void _mergeStop(TransitStop stop) {
    final routeStops = _stopsByRouteId.putIfAbsent(stop.routeId, () => []);
    final existingIndex =
        routeStops.indexWhere((existing) => existing.stopId == stop.stopId);
    if (existingIndex >= 0) {
      routeStops[existingIndex] = stop;
    } else {
      routeStops.add(stop);
    }

    final flatIndex =
        _stops.indexWhere((existing) => existing.stopId == stop.stopId);
    if (flatIndex >= 0) {
      _stops[flatIndex] = stop;
    } else {
      _stops.add(stop);
    }
  }

  Future<void> reloadCachedFeeds(List<GtfsCachedFeed> cachedFeeds) async {
    await reinitialize(cachedFeeds: cachedFeeds);
  }

  Future<void> reinitialize({
    List<GtfsCachedFeed> cachedFeeds = const [],
  }) async {
    _initialized = false;
    _agencies.clear();
    _routes.clear();
    _stops.clear();
    _agenciesById.clear();
    _routesById.clear();
    _stopsByRouteId.clear();
    await initializeFromFallbackData(cachedFeeds: cachedFeeds);
  }

  void _removeTransitSystemData(String transitSystem) {
    final routeIdsToRemove = _routes
        .where((route) => route.transitSystem == transitSystem)
        .map((route) => route.routeId)
        .toSet();

    if (routeIdsToRemove.isEmpty) {
      return;
    }

    _routes.removeWhere((route) => routeIdsToRemove.contains(route.routeId));
    for (final routeId in routeIdsToRemove) {
      _routesById.remove(routeId);
      final routeStops = _stopsByRouteId.remove(routeId);
      if (routeStops == null) {
        continue;
      }
      final stopIds = routeStops.map((stop) => stop.stopId).toSet();
      _stops.removeWhere((stop) => stopIds.contains(stop.stopId));
    }
  }

  Future<void> _loadJsonFallbackForSystem({
    required String country,
    required String transitSystem,
    required String agencyId,
  }) async {
    for (final lineName in TransitCatalog.linesForSystem(transitSystem)) {
      final result = await _transitDataService.loadLine(
        country: country,
        transitSystem: transitSystem,
        lineName: lineName,
      );

      if (result.line == null || result.line!.stations.isEmpty) {
        AppLog.d(
          'GtfsService: skipped empty JSON fallback for $lineName '
          '(${result.error ?? 'no stations'})',
        );
        continue;
      }

      final routeId = _routeIdFor(agencyId, lineName);
      final route = TransitRoute(
        routeId: routeId,
        routeName: lineName,
        agencyId: agencyId,
        country: country,
        lineName: lineName,
        transitSystem: transitSystem,
        vehicleType: _defaultVehicleTypeForSystem(transitSystem),
      );
      _routes.add(route);
      _routesById[routeId] = route;

      final routeStops = result.line!.stations
          .map(
            (station) => TransitStop(
              stopId: '$routeId:${station.stationOrder}',
              stopName: station.name,
              latitude: station.latitude,
              longitude: station.longitude,
              routeId: routeId,
              stopSequence: station.stationOrder,
            ),
          )
          .toList(growable: false);

      _stops.addAll(routeStops);
      _stopsByRouteId[routeId] = routeStops;

      AppLog.d(
        'GtfsService: loaded JSON fallback $routeId (${routeStops.length} stops)',
      );
    }
  }

  String _routeIdFor(String agencyId, String lineName) {
    final normalizedLine = lineName.replaceAll(' ', '_').toLowerCase();
    return '${agencyId}_$normalizedLine';
  }

  List<TransitStop> searchStops(String query, {int limit = 20}) {
    return searchStopResults(query, limit: limit)
        .map((result) => result.stop)
        .toList(growable: false);
  }

  List<TransitStopSearchResult> searchStopResults(
    String query, {
    int limit = 20,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final matches = <TransitStopSearchResult>[];
    for (final stop in _stops) {
      if (!stop.stopName.toLowerCase().contains(normalizedQuery)) {
        continue;
      }

      final route = _routesById[stop.routeId];
      final agency = route == null ? null : _agenciesById[route.agencyId];
      matches.add(
        TransitStopSearchResult(
          stop: stop,
          agencyName: agency?.agencyName ?? route?.transitSystem ?? 'Transit',
          routeName: route?.routeName ?? route?.lineName ?? 'Route',
          vehicleType: route?.vehicleType ?? TransitVehicleType.bus,
        ),
      );

      if (matches.length >= limit) {
        break;
      }
    }

    AppLog.d(
      'GtfsService: search "$query" returned ${matches.length} matches',
    );
    return matches;
  }

  TransitVehicleType _defaultVehicleTypeForSystem(String transitSystem) {
    return switch (transitSystem) {
      'GO Transit' || 'Exo' => TransitVehicleType.train,
      'TTC' => TransitVehicleType.subway,
      _ => TransitVehicleType.bus,
    };
  }

  AgencyDetectionResult? detectAgencyFromDestination(String destinationName) {
    return detectAgencyFromDestinationAt(
      destinationName: destinationName,
    );
  }

  AgencyDetectionResult? detectAgencyFromDestinationAt({
    required String destinationName,
    double? latitude,
    double? longitude,
    double maxDistanceMeters = 250,
  }) {
    if (latitude != null && longitude != null) {
      final nearestStop = findNearestStop(
        latitude: latitude,
        longitude: longitude,
        maxDistanceMeters: maxDistanceMeters,
      );
      if (nearestStop != null) {
        return _detectionForStop(nearestStop);
      }
    }

    final normalizedName = destinationName.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return null;
    }

    final exactMatches = _stops
        .where((stop) => stop.stopName.toLowerCase() == normalizedName)
        .toList(growable: false);

    if (exactMatches.isNotEmpty) {
      final stop = _pickBestStopMatch(exactMatches, normalizedName);
      return _detectionForStop(stop);
    }

    final partialMatches = _stops
        .where((stop) => stop.stopName.toLowerCase().contains(normalizedName))
        .toList(growable: false);

    if (partialMatches.isNotEmpty) {
      final stop = _pickBestStopMatch(partialMatches, normalizedName);
      return _detectionForStop(stop);
    }

    return _detectFromHeuristics(normalizedName);
  }

  TransitStop? findNearestStop({
    required double latitude,
    required double longitude,
    double maxDistanceMeters = 250,
  }) {
    if (_stops.isEmpty) {
      return null;
    }

    return _findNearestStopInList(
      _stops,
      latitude: latitude,
      longitude: longitude,
      maxDistanceMeters: maxDistanceMeters,
    );
  }

  TransitStop? findNearestStopOnRoute({
    required double latitude,
    required double longitude,
    required String routeId,
    double maxDistanceMeters = 250,
  }) {
    final routeStops = _stopsByRouteId[routeId] ?? const [];
    if (routeStops.isEmpty) {
      return null;
    }

    return _findNearestStopInList(
      routeStops,
      latitude: latitude,
      longitude: longitude,
      maxDistanceMeters: maxDistanceMeters,
    );
  }

  AgencyDetectionResult? detectDestinationOnRoute({
    required String destinationName,
    required String routeId,
    double? latitude,
    double? longitude,
    double maxDistanceMeters = 250,
  }) {
    final byName = findStopByName(destinationName, routeId: routeId);
    if (byName != null) {
      return _detectionForStop(byName);
    }

    final normalizedName = destinationName.trim().toLowerCase();
    if (normalizedName.isNotEmpty) {
      final routeStops = _stopsByRouteId[routeId] ?? const [];
      final exactMatches = routeStops
          .where((stop) => stop.stopName.toLowerCase() == normalizedName)
          .toList(growable: false);
      if (exactMatches.isNotEmpty) {
        return _detectionForStop(
          _pickBestStopMatch(exactMatches, normalizedName),
        );
      }

      final partialMatches = routeStops
          .where((stop) => stop.stopName.toLowerCase().contains(normalizedName))
          .toList(growable: false);
      if (partialMatches.length == 1) {
        return _detectionForStop(partialMatches.first);
      }
    }

    if (latitude != null && longitude != null) {
      final nearestStop = findNearestStopOnRoute(
        latitude: latitude,
        longitude: longitude,
        routeId: routeId,
        maxDistanceMeters: maxDistanceMeters,
      );
      if (nearestStop != null) {
        return _detectionForStop(nearestStop);
      }
    }

    return null;
  }

  TransitStop? _findNearestStopInList(
    Iterable<TransitStop> stops, {
    required double latitude,
    required double longitude,
    required double maxDistanceMeters,
  }) {
    TransitStop? nearest;
    var nearestDistance = maxDistanceMeters;

    for (final stop in stops) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        stop.latitude,
        stop.longitude,
      );
      if (distance <= nearestDistance) {
        nearestDistance = distance;
        nearest = stop;
      }
    }

    return nearest;
  }

  String? transitBadgeForStop(TransitStop stop) {
    final route = _routesById[stop.routeId];
    if (route == null) {
      return null;
    }
    return transitLineInfoForRoute(route).badge;
  }

  TransitRoute? routeForStop(TransitStop stop) => _routesById[stop.routeId];

  TransitStop? findStopByName(String stopName, {String? routeId}) {
    final normalizedName = stopName.trim().toLowerCase();
    Iterable<TransitStop> candidates = _stops;
    if (routeId != null) {
      candidates = _stopsByRouteId[routeId] ?? const [];
    }

    for (final stop in candidates) {
      if (stop.stopName.toLowerCase() == normalizedName) {
        return stop;
      }
    }
    return null;
  }

  TransitRoute? routeById(String routeId) => _routesById[routeId];

  TransitAgency? agencyById(String agencyId) => _agenciesById[agencyId];

  List<TransitStop> stopsForRoute(String routeId) {
    return _dedupeStopsByLocation(_stopsByRouteId[routeId] ?? const []);
  }

  static List<TransitStop> _dedupeStopsByLocation(List<TransitStop> stops) {
    final seenKeys = <String>{};
    final deduped = <TransitStop>[];
    for (final stop in stops) {
      final key =
          '${stop.stopName}|${stop.latitude.toStringAsFixed(5)}|${stop.longitude.toStringAsFixed(5)}';
      if (seenKeys.add(key)) {
        deduped.add(stop);
      }
    }
    deduped.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return deduped;
  }

  List<TransitRoute> routesForTransitSystem(String transitSystem) {
    return _routes
        .where((route) => route.transitSystem == transitSystem)
        .toList(growable: false);
  }

  List<TransitVehicleType> vehicleTypesForTransitSystem(String transitSystem) {
    final routes = routesForTransitSystem(transitSystem);
    if (routes.isNotEmpty) {
      final types = routes.map((route) => route.vehicleType).toSet().toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      return types;
    }

    final feed = TransitCatalog.feedByAgencyName(transitSystem);
    return feed?.vehicleTypes ?? const [];
  }

  bool hasGtfsRoutesForTransitSystem(String transitSystem) {
    return routesForTransitSystem(transitSystem).isNotEmpty;
  }

  List<String> linesForTransitSystem(
    String transitSystem, {
    TransitVehicleType? vehicleType,
  }) {
    return lineOptionsForTransitSystem(
      transitSystem,
      vehicleType: vehicleType,
    ).map((option) => option.lineName).toList(growable: false);
  }

  List<TransitLineOption> lineOptionsForTransitSystem(
    String transitSystem, {
    TransitVehicleType? vehicleType,
  }) {
    final routes = routesForTransitSystem(transitSystem);
    if (routes.isNotEmpty) {
      final filteredRoutes = vehicleType == null
          ? routes
          : routes.where((route) => route.vehicleType == vehicleType);
      final options = _lineOptionsFromRoutes(filteredRoutes);
      if (options.isNotEmpty) {
        return options;
      }
      if (vehicleType != null) {
        return const [];
      }
    }

    if (TransitCatalog.hasCatalogLines(transitSystem)) {
      final catalogLines = TransitCatalog.linesForSystem(transitSystem);
      if (vehicleType == null ||
          vehicleType == _defaultVehicleTypeForSystem(transitSystem)) {
        return catalogLines
            .map(
              (line) => TransitLineOption(
                lineName: line,
                displayLabel: line,
              ),
            )
            .toList(growable: false);
      }
      return const [];
    }

    final options = _lineOptionsFromRoutes(routes);
    if (options.isNotEmpty) {
      return options;
    }

    return TransitCatalog.linesForSystem(transitSystem)
        .map(
          (line) => TransitLineOption(
            lineName: line,
            displayLabel: line,
          ),
        )
        .toList(growable: false);
  }

  String displayLabelForLine(String transitSystem, String lineName) {
    for (final route in routesForTransitSystem(transitSystem)) {
      if (route.lineName == lineName ||
          route.routeName == lineName ||
          route.routeShortName == lineName) {
        return TransitLineOption.fromRoute(route).displayLabel;
      }
    }
    return lineName;
  }

  List<TransitLineOption> _lineOptionsFromRoutes(
    Iterable<TransitRoute> routes,
  ) {
    final optionsByLineName = <String, TransitLineOption>{};
    for (final route in routes) {
      optionsByLineName.putIfAbsent(
        route.lineName,
        () => TransitLineOption.fromRoute(route),
      );
    }

    final options = optionsByLineName.values.toList(growable: false)
      ..sort(
        (a, b) => _compareLineNames(a.displayLabel, b.displayLabel),
      );
    return options;
  }

  bool hasStopsForTransitSystem(String transitSystem) {
    for (final route in routesForTransitSystem(transitSystem)) {
      if (stopsForRoute(route.routeId).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  List<TransitStopSearchResult> searchStopsForTransitSystem(
    String transitSystem,
    String query, {
    int limit = 100,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final results = <TransitStopSearchResult>[];
    final seenStopKeys = <String>{};

    for (final route in routesForTransitSystem(transitSystem)) {
      final agency = _agenciesById[route.agencyId];
      for (final stop in stopsForRoute(route.routeId)) {
        if (normalizedQuery.isNotEmpty &&
            !stop.stopName.toLowerCase().contains(normalizedQuery)) {
          continue;
        }

        final stopKey =
            '${stop.stopName}|${stop.latitude}|${stop.longitude}';
        if (seenStopKeys.contains(stopKey)) {
          continue;
        }
        seenStopKeys.add(stopKey);

        results.add(
          TransitStopSearchResult(
            stop: stop,
            agencyName: agency?.agencyName ?? route.transitSystem,
            routeName: route.routeName,
            vehicleType: route.vehicleType,
          ),
        );

        if (results.length >= limit) {
          break;
        }
      }

      if (results.length >= limit) {
        break;
      }
    }

    results.sort(
      (a, b) => a.stop.stopName.toLowerCase().compareTo(
            b.stop.stopName.toLowerCase(),
          ),
    );
    return results;
  }

  TransitRoute? routeForTransitLine({
    required String transitSystem,
    required String lineName,
  }) {
    final normalized = lineName.trim();
    if (normalized.isEmpty) {
      return null;
    }

    for (final route in _routes) {
      if (route.transitSystem != transitSystem) {
        continue;
      }
      if (_routeMatchesLineRef(route, normalized)) {
        return route;
      }
    }
    return null;
  }

  String? resolvePreferenceLineName({
    required String transitSystem,
    required String lineRef,
  }) {
    return routeForTransitLine(
      transitSystem: transitSystem,
      lineName: lineRef,
    )?.lineName;
  }

  bool routeExistsForLineRef({
    required String transitSystem,
    required String lineRef,
  }) {
    return routeForTransitLine(
      transitSystem: transitSystem,
      lineName: lineRef,
    ) != null;
  }

  ({String badge, String lineName}) transitLineInfoForRoute(TransitRoute route) {
    final displayLabel = route.routeName.isNotEmpty &&
            route.routeName != route.lineName
        ? route.routeName
        : route.lineName;
    return (
      badge: '${route.transitSystem} · $displayLabel',
      lineName: route.lineName,
    );
  }

  bool _routeMatchesLineRef(TransitRoute route, String lineRef) {
    final normalized = lineRef.toLowerCase();
    return route.lineName.toLowerCase() == normalized ||
        route.routeName.toLowerCase() == normalized ||
        (route.routeShortName?.toLowerCase() == normalized);
  }

  List<TransitStop> stopsForTransitLine({
    required String transitSystem,
    required String lineName,
  }) {
    final route = routeForTransitLine(
      transitSystem: transitSystem,
      lineName: lineName,
    );
    if (route == null) {
      return const [];
    }

    final stops = List<TransitStop>.from(stopsForRoute(route.routeId))
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return stops;
  }

  List<TransitStop> filterStopsOnRoute({
    required String routeId,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final routeStops = stopsForRoute(routeId);
    if (normalizedQuery.isEmpty) {
      return List<TransitStop>.from(routeStops)
        ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    }

    return routeStops
        .where(
          (stop) => stop.stopName.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false)
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
  }

  bool hasStopsForTransitLine({
    required String transitSystem,
    required String lineName,
  }) {
    return stopsForTransitLine(
      transitSystem: transitSystem,
      lineName: lineName,
    ).isNotEmpty;
  }

  AgencyDetectionResult? _detectionForStop(TransitStop stop) {
    final route = _routesById[stop.routeId];
    final agency = route == null ? null : _agenciesById[route.agencyId];
    if (agency == null) {
      return null;
    }

    AppLog.d(
      'GtfsService: detected ${agency.agencyName} / ${route!.lineName} '
      'for ${stop.stopName}',
    );

    return AgencyDetectionResult(
      agency: agency,
      route: route,
      stop: stop,
    );
  }

  TransitStop _pickBestStopMatch(List<TransitStop> matches, String query) {
    if (matches.length == 1) {
      return matches.first;
    }

    final goMatches = matches
        .where((stop) => stop.stopName.toLowerCase().endsWith(' go'))
        .toList();
    if (query.endsWith(' go') && goMatches.isNotEmpty) {
      return goMatches.first;
    }

    return matches.first;
  }

  AgencyDetectionResult? _detectFromHeuristics(String normalizedName) {
    if (normalizedName.contains('montreal central') ||
        normalizedName.contains('gare centrale')) {
      return _detectionForNamedStop('Montreal Central');
    }

    if (normalizedName.contains('penn station')) {
      return _detectionForNamedStop('Penn Station');
    }

    if (normalizedName.contains('waterloo station')) {
      return _detectionForNamedStop('Waterloo Station');
    }

    if (normalizedName.endsWith(' go')) {
      final agency = _agenciesById['go_transit'];
      if (agency == null) {
        return null;
      }

      final goStop = findStopByName(normalizedName);
      if (goStop != null) {
        return _detectionForStop(goStop);
      }

      return AgencyDetectionResult(agency: agency);
    }

    return null;
  }

  AgencyDetectionResult? _detectionForNamedStop(String stopName) {
    final stop = findStopByName(stopName);
    if (stop == null) {
      return null;
    }
    return _detectionForStop(stop);
  }

  Future<void> downloadGtfsFeeds() async {
    AppLog.d('GtfsService: downloadGtfsFeeds() is not implemented yet.');
  }

  Future<void> refreshFeeds() async {
    AppLog.d('GtfsService: refreshFeeds() is not implemented yet.');
  }

  Future<void> downloadRealtimeFeed(String agencyId) async {
    AppLog.d(
      'GtfsService: downloadRealtimeFeed($agencyId) is not implemented yet.',
    );
  }

  Future<void> updateRealtimeVehicles(String agencyId) async {
    AppLog.d(
      'GtfsService: updateRealtimeVehicles($agencyId) is not implemented yet.',
    );
  }

  Future<void> syncAllFeeds() async {
    AppLog.d('GtfsService: syncAllFeeds() is not implemented yet.');
  }

  bool supportsRealtime(String agencyId) {
    final agency = _agenciesById[agencyId];
    if (agency == null) {
      return false;
    }
    return agency.supportsRealtime;
  }

  int _compareLineNames(String a, String b) {
    final aMatch = RegExp(r'^(\d+)').firstMatch(a);
    final bMatch = RegExp(r'^(\d+)').firstMatch(b);
    final aNumber = int.tryParse(aMatch?.group(1) ?? '');
    final bNumber = int.tryParse(bMatch?.group(1) ?? '');

    if (aNumber != null && bNumber != null && aNumber != bNumber) {
      return aNumber.compareTo(bNumber);
    }

    return a.toLowerCase().compareTo(b.toLowerCase());
  }
}
