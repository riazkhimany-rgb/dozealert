import 'package:flutter/foundation.dart';

import '../cache/gtfs_cache_store.dart';
import '../data/transit_catalog.dart';
import '../models/agency_detection_result.dart';
import '../models/transit_agency.dart';
import '../models/transit_route.dart';
import '../models/transit_stop.dart';
import 'transit_data_service.dart';

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

  static const seededAgencies = <TransitAgency>[
    TransitAgency(
      agencyId: 'go_transit',
      agencyName: 'GO Transit',
      country: 'Canada',
      city: 'Toronto',
    ),
    TransitAgency(
      agencyId: 'ttc',
      agencyName: 'TTC',
      country: 'Canada',
      city: 'Toronto',
    ),
    TransitAgency(
      agencyId: 'stm_montreal',
      agencyName: 'STM Montreal',
      country: 'Canada',
      city: 'Montreal',
    ),
    TransitAgency(
      agencyId: 'exo_montreal',
      agencyName: 'Exo Montreal',
      country: 'Canada',
      city: 'Montreal',
    ),
    TransitAgency(
      agencyId: 'translink_vancouver',
      agencyName: 'TransLink Vancouver',
      country: 'Canada',
      city: 'Vancouver',
    ),
    TransitAgency(
      agencyId: 'oc_transpo',
      agencyName: 'OC Transpo',
      country: 'Canada',
      city: 'Ottawa',
    ),
    TransitAgency(
      agencyId: 'amtrak',
      agencyName: 'Amtrak',
      country: 'United States',
      city: 'National',
    ),
    TransitAgency(
      agencyId: 'mta',
      agencyName: 'MTA',
      country: 'United States',
      city: 'New York',
    ),
    TransitAgency(
      agencyId: 'national_rail',
      agencyName: 'National Rail',
      country: 'United Kingdom',
      city: 'National',
    ),
    TransitAgency(
      agencyId: 'london_underground',
      agencyName: 'London Underground',
      country: 'United Kingdom',
      city: 'London',
    ),
  ];

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

    await _loadGoTransitJsonFallback();
    _loadSupplementalStops();

    for (final feed in cachedFeeds) {
      mergeCachedFeed(feed);
    }

    _initialized = true;
    debugPrint(
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

    debugPrint(
      'GtfsService: merged cached feed ${feed.info.feedName} '
      '(${feed.stops.length} stops)',
    );
  }

  Future<void> reloadCachedFeeds(List<GtfsCachedFeed> cachedFeeds) async {
    for (final feed in cachedFeeds) {
      mergeCachedFeed(feed);
    }
  }

  Future<void> _loadGoTransitJsonFallback() async {
    const country = 'Canada';
    const transitSystem = 'GO Transit';
    const agencyId = 'go_transit';

    for (final lineName in TransitCatalog.linesForSystem(transitSystem)) {
      final result = await _transitDataService.loadLine(
        country: country,
        transitSystem: transitSystem,
        lineName: lineName,
      );

      if (result.line == null || result.line!.stations.isEmpty) {
        debugPrint(
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

      debugPrint(
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
    _addSupplementalRoute(
      agencyId: 'national_rail',
      transitSystem: 'National Rail',
      lineName: 'West Coast Main Line',
      stops: const [
        _SupplementalStop(
          name: 'Waterloo Station',
          latitude: 51.5033,
          longitude: -0.1147,
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
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final matches = _stops
        .where(
          (stop) => stop.stopName.toLowerCase().contains(normalizedQuery),
        )
        .take(limit)
        .toList(growable: false);

    debugPrint(
      'GtfsService: search "$query" returned ${matches.length} matches',
    );
    return matches;
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

  AgencyDetectionResult? _detectionForStop(TransitStop stop) {
    final route = _routesById[stop.routeId];
    final agency = route == null ? null : _agenciesById[route.agencyId];
    if (agency == null) {
      return null;
    }

    debugPrint(
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
    debugPrint('GtfsService: downloadGtfsFeeds() is not implemented yet.');
  }

  Future<void> refreshFeeds() async {
    debugPrint('GtfsService: refreshFeeds() is not implemented yet.');
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
