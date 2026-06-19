import '../cache/gtfs_cache_store.dart';
import '../data/transit_catalog.dart';
import '../models/agency_detection_result.dart';
import '../models/transit_agency.dart';
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

    await _loadJsonFallbackForSystem(
      country: 'Canada',
      transitSystem: 'GO Transit',
      agencyId: 'go_transit',
    );
    await _loadJsonFallbackForSystem(
      country: 'Canada',
      transitSystem: 'TTC',
      agencyId: 'ttc',
    );
    _loadSupplementalStops();

    for (final feed in cachedFeeds) {
      mergeCachedFeed(feed);
    }

    _initialized = true;
    AppLog.d(
      'GtfsService: initialized ${_stops.length} stops across ${_routes.length} routes',
    );
  }

  void mergeCachedFeed(GtfsCachedFeed feed) {
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
      final routeStops = _stopsByRouteId.putIfAbsent(stop.routeId, () => []);
      routeStops.removeWhere((existing) => existing.stopId == stop.stopId);
      routeStops.add(stop);
      _stops.removeWhere((existing) => existing.stopId == stop.stopId);
      _stops.add(stop);
    }

    AppLog.d(
      'GtfsService: merged cached feed ${feed.info.feedName} '
      '(${feed.stops.length} stops)',
    );
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

  void _loadSupplementalStops() {
    _addSupplementalRoute(
      agencyId: 'exo_montreal',
      transitSystem: 'Exo',
      lineName: 'Mont-Saint-Hilaire',
      stops: const [
        _SupplementalStop(
          name: 'Montreal Central',
          latitude: 45.5001,
          longitude: -73.5694,
          sequence: 1,
        ),
      ],
    );
    _addSupplementalRoute(
      agencyId: 'amtrak',
      transitSystem: 'Amtrak',
      lineName: 'Northeast Regional',
      stops: const [
        _SupplementalStop(
          name: 'Penn Station',
          latitude: 40.7506,
          longitude: -73.9935,
          sequence: 1,
        ),
      ],
    );
  }

  void _addSupplementalRoute({
    required String agencyId,
    required String transitSystem,
    required String lineName,
    required List<_SupplementalStop> stops,
  }) {
    final agency = _agenciesById[agencyId];
    if (agency == null) {
      return;
    }

    final routeId = _routeIdFor(agencyId, lineName);
    if (_routesById.containsKey(routeId)) {
      return;
    }

    final route = TransitRoute(
      routeId: routeId,
      routeName: lineName,
      agencyId: agencyId,
      country: agency.country,
      lineName: lineName,
      transitSystem: transitSystem,
    );
    _routes.add(route);
    _routesById[routeId] = route;

    final routeStops = stops
        .map(
          (stop) => TransitStop(
            stopId: '$routeId:${stop.sequence}',
            stopName: stop.name,
            latitude: stop.latitude,
            longitude: stop.longitude,
            routeId: routeId,
            stopSequence: stop.sequence,
          ),
        )
        .toList(growable: false);

    _stops.addAll(routeStops);
    _stopsByRouteId[routeId] = routeStops;
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
    return _stopsByRouteId[routeId] ?? const [];
  }

  TransitRoute? routeForTransitLine({
    required String transitSystem,
    required String lineName,
  }) {
    for (final route in _routes) {
      if (route.transitSystem == transitSystem &&
          (route.lineName == lineName || route.routeName == lineName)) {
        return route;
      }
    }
    return null;
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
}

class _SupplementalStop {
  const _SupplementalStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int sequence;
}
