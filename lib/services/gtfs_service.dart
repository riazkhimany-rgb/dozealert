import 'package:geolocator/geolocator.dart';

import '../cache/gtfs_cache_store.dart';
import '../data/transit_catalog.dart';
import '../models/agency_detection_result.dart';
import '../models/destination.dart';
import '../models/route_shape_polyline.dart';
import '../models/transit_agency.dart';
import '../models/transit_line_option.dart';
import '../models/transit_route.dart';
import '../models/gtfs_station.dart';
import '../models/gtfs_station_search_result.dart';
import '../models/transit_stop.dart';
import '../models/transit_stop_search_result.dart';
import '../models/transit_vehicle_type.dart';
import '../utils/geo_heading_utils.dart';
import '../utils/gtfs_station_utils.dart';
import '../utils/gtfs_stop_name_utils.dart';
import '../utils/app_log.dart';

class GtfsService {
  GtfsService();

  bool _initialized = false;
  final List<TransitAgency> _agencies = [];
  final List<TransitRoute> _routes = [];
  final List<TransitStop> _stops = [];
  final Map<String, TransitAgency> _agenciesById = {};
  final Map<String, TransitRoute> _routesById = {};
  final Map<String, List<TransitStop>> _stopsByRouteId = {};
  final Map<String, List<RouteShapePoint>> _shapePointsByKey = {};

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
    _shapePointsByKey.clear();

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

    for (final shape in feed.shapes) {
      _shapePointsByKey[shape.storageKey] = shape.points;
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

    for (final shape in feed.shapes) {
      _shapePointsByKey[shape.storageKey] = shape.points;
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
    _shapePointsByKey.clear();
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

    _shapePointsByKey.removeWhere(
      (key, _) => routeIdsToRemove.any((routeId) => key.startsWith('$routeId|')),
    );
  }

  List<RouteShapePoint>? shapePointsForPattern({
    required String routeId,
    String? patternKey,
  }) {
    if (patternKey == null || patternKey.isEmpty) {
      return null;
    }
    return _shapePointsByKey['$routeId|$patternKey'];
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

  TransitStop? findStopByName(
    String stopName, {
    String? routeId,
    List<TransitStop>? routeStops,
  }) {
    Iterable<TransitStop> candidates;
    if (routeStops != null) {
      candidates = routeStops;
    } else if (routeId != null) {
      candidates = _stopsByRouteId[routeId] ?? const [];
    } else {
      candidates = _stops;
    }

    for (final stop in candidates) {
      if (GtfsStopNameUtils.namesMatch(stop.stopName, stopName)) {
        return stop;
      }
    }
    return null;
  }

  String stationDisplayName(String rawName) =>
      GtfsStopNameUtils.stationDisplayName(rawName);

  String stationKeyForStop(TransitStop stop) =>
      GtfsStationUtils.stationKeyForStop(stop);

  GtfsStation stationFromStop(TransitStop stop) =>
      GtfsStationUtils.stationFromStop(stop);

  /// Resolves a saved destination to the stop on [stops] (locked pattern).
  TransitStop? resolveStopAmongStops({
    required Destination destination,
    required List<TransitStop> stops,
  }) {
    final displayName = stationDisplayName(destination.name);

    for (final stop in stops) {
      if (GtfsStopNameUtils.namesMatch(stop.stopName, displayName)) {
        return stop;
      }
    }

    if (destination.stationKey != null) {
      for (final stop in stops) {
        if (stationKeyForStop(stop) == destination.stationKey) {
          return stop;
        }
      }
    }

    return findStopByName(destination.name, routeStops: stops);
  }

  /// Nearest stop on [pattern] for GPS, preferring one platform per station.
  TransitStop? resolveCurrentOnPattern({
    required double latitude,
    required double longitude,
    required List<TransitStop> pattern,
    required int maxProximityMeters,
    TransitStop? destinationOnPattern,
  }) {
    if (pattern.isEmpty) {
      return null;
    }

    final candidates = <TransitStop>[];
    for (final stop in pattern) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        stop.latitude,
        stop.longitude,
      );
      if (distance <= maxProximityMeters) {
        candidates.add(stop);
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    TransitStop nearest = candidates.first;
    var nearestDistance = Geolocator.distanceBetween(
      latitude,
      longitude,
      nearest.latitude,
      nearest.longitude,
    );
    for (final stop in candidates.skip(1)) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        stop.latitude,
        stop.longitude,
      );
      if (distance < nearestDistance) {
        nearest = stop;
        nearestDistance = distance;
      }
    }

    final stationKey = stationKeyForStop(nearest);
    final atStation = pattern
        .where((stop) => stationKeyForStop(stop) == stationKey)
        .toList();
    if (atStation.length <= 1) {
      return nearest;
    }

    if (destinationOnPattern != null) {
      final travelingForward =
          destinationOnPattern.stopSequence >= nearest.stopSequence;
      atStation.sort(
        (a, b) => travelingForward
            ? a.stopSequence.compareTo(b.stopSequence)
            : b.stopSequence.compareTo(a.stopSequence),
      );
      return atStation.first;
    }

    return nearest;
  }

  /// Human-readable label for a locked direction/headsign pattern key.
  static String? directionLabelForPatternKey(String? patternKey) {
    if (patternKey == null || patternKey.isEmpty || patternKey == 'legacy') {
      return null;
    }
    if (patternKey.startsWith('h:')) {
      return patternKey
          .substring(2)
          .replaceAll('_', ' ')
          .trim();
    }
    if (patternKey.startsWith('d:')) {
      return 'Direction ${patternKey.substring(2)}';
    }
    return null;
  }

  List<GtfsStation> stationsOnRoute({
    required String routeId,
    String query = '',
  }) {
    return GtfsStationUtils.dedupeStopsToStations(
      stopsForRoute(routeId),
      query: query,
    );
  }

  List<GtfsStationSearchResult> searchStationsForTransitSystem(
    String transitSystem,
    String query, {
    int limit = 100,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final results = <GtfsStationSearchResult>[];
    final seenKeys = <String>{};

    for (final route in routesForTransitSystem(transitSystem)) {
      final agency = _agenciesById[route.agencyId];
      for (final station in stationsOnRoute(routeId: route.routeId)) {
        if (normalizedQuery.isNotEmpty &&
            !station.name.toLowerCase().contains(normalizedQuery)) {
          continue;
        }

        final dedupeKey = '${station.stationKey}|${route.routeId}';
        if (seenKeys.contains(dedupeKey)) {
          continue;
        }
        seenKeys.add(dedupeKey);

        results.add(
          GtfsStationSearchResult(
            station: station,
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
      (a, b) => a.station.name.toLowerCase().compareTo(
            b.station.name.toLowerCase(),
          ),
    );
    return results;
  }

  List<GtfsStation> filterStationsOnRoute({
    required String routeId,
    required String query,
  }) {
    return stationsOnRoute(routeId: routeId, query: query);
  }

  TransitRoute? routeById(String routeId) => _routesById[routeId];

  TransitAgency? agencyById(String agencyId) => _agenciesById[agencyId];

  List<TransitStop> stopsForRoute(
    String routeId, {
    TransitStop? destinationStop,
    TransitStop? anchorStop,
    double? latitude,
    double? longitude,
    String? lockedPatternKey,
    double? headingDegrees,
    double? speedMps,
  }) {
    final raw = _stopsByRouteId[routeId] ?? const [];
    if (raw.isEmpty) {
      return const [];
    }

    final patterns = _directionPatternsFrom(raw);
    if (lockedPatternKey != null) {
      final locked = patterns[lockedPatternKey];
      if (locked != null) {
        return List<TransitStop>.from(locked);
      }
    }

    if (patterns.length <= 1) {
      final pattern = patterns.values.firstOrNull;
      if (pattern == null) {
        return _dedupeStopsByLocation(raw);
      }
      return List<TransitStop>.from(pattern);
    }

    if (destinationStop != null ||
        anchorStop != null ||
        (latitude != null && longitude != null)) {
      return _selectDirectionPattern(
        patterns: patterns.values.toList(growable: false),
        destinationStop: destinationStop,
        anchorStop: anchorStop,
        latitude: latitude,
        longitude: longitude,
        headingDegrees: headingDegrees,
        speedMps: speedMps,
      );
    }

    return patterns.values.reduce(
      (a, b) => a.length >= b.length ? a : b,
    );
  }

  /// Infers the best-matching direction/headsign pattern key for GPS context.
  String? inferPatternKeyForRoute(
    String routeId, {
    TransitStop? destinationStop,
    TransitStop? anchorStop,
    double? latitude,
    double? longitude,
    double? headingDegrees,
    double? speedMps,
  }) {
    final raw = _stopsByRouteId[routeId] ?? const [];
    if (raw.isEmpty) {
      return null;
    }

    final patterns = _directionPatternsFrom(raw);
    if (patterns.isEmpty) {
      return null;
    }
    if (patterns.length == 1) {
      return patterns.keys.first;
    }

    final selected = _selectDirectionPattern(
      patterns: patterns.values.toList(growable: false),
      destinationStop: destinationStop,
      anchorStop: anchorStop,
      latitude: latitude,
      longitude: longitude,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
    );
    if (selected.isEmpty) {
      return null;
    }
    return patternKeyFromStopId(selected.first.stopId);
  }

  static final _patternStopIdPattern = RegExp(r':(d\d+|h[a-z0-9_]+):s\d+$');

  static String? patternKeyFromStopId(String stopId) {
    final token = _patternStopIdPattern.firstMatch(stopId)?.group(1);
    if (token == null) {
      return null;
    }
    if (token.startsWith('h')) {
      return 'h:${token.substring(1)}';
    }
    return 'd:${token.substring(1)}';
  }

  @Deprecated('Use patternKeyFromStopId')
  static String? directionIdFromStopId(String stopId) {
    final key = patternKeyFromStopId(stopId);
    if (key == null || !key.startsWith('d:')) {
      return null;
    }
    return key.substring(2);
  }

  static Map<String, List<TransitStop>> _directionPatternsFrom(
    List<TransitStop> stops,
  ) {
    final hasPatternKeys = stops.any(
      (stop) => patternKeyFromStopId(stop.stopId) != null,
    );
    if (!hasPatternKeys) {
      final legacy = List<TransitStop>.from(stops)
        ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
      return {'legacy': legacy};
    }

    final patterns = <String, List<TransitStop>>{};
    for (final stop in stops) {
      final patternKey = patternKeyFromStopId(stop.stopId) ?? 'legacy';
      patterns.putIfAbsent(patternKey, () => []).add(stop);
    }

    for (final pattern in patterns.values) {
      pattern.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    }
    return patterns;
  }

  static List<TransitStop> _selectDirectionPattern({
    required List<List<TransitStop>> patterns,
    TransitStop? destinationStop,
    TransitStop? anchorStop,
    double? latitude,
    double? longitude,
    double? headingDegrees,
    double? speedMps,
  }) {
    if (destinationStop != null && anchorStop != null) {
      final bothMatching = patterns
          .where(
            (pattern) =>
                _patternContainsStop(pattern, destinationStop) &&
                _patternContainsStop(pattern, anchorStop),
          )
          .toList(growable: false);
      if (bothMatching.length == 1) {
        return bothMatching.first;
      }
      if (bothMatching.isNotEmpty) {
        return _pickPatternForTrip(
          bothMatching,
          anchorStop: anchorStop,
          destinationStop: destinationStop,
          latitude: latitude,
          longitude: longitude,
          headingDegrees: headingDegrees,
          speedMps: speedMps,
        );
      }
    }

    Iterable<List<TransitStop>> candidates = patterns;
    if (destinationStop != null) {
      final matching = patterns
          .where(
            (pattern) => _patternContainsStop(pattern, destinationStop),
          )
          .toList(growable: false);
      if (matching.isNotEmpty) {
        candidates = matching;
      }
    } else if (anchorStop != null) {
      final matching = patterns
          .where((pattern) => _patternContainsStop(pattern, anchorStop))
          .toList(growable: false);
      if (matching.isNotEmpty) {
        candidates = matching;
      }
    }

    final candidateList = candidates.toList(growable: false);
    if (candidateList.length == 1) {
      return candidateList.first;
    }

    if (latitude != null &&
        longitude != null &&
        destinationStop != null) {
      List<TransitStop>? bestPattern;
      var bestScore = double.negativeInfinity;

      for (final pattern in candidateList) {
        final destinationOnPattern = _findMatchingStop(pattern, destinationStop);
        if (destinationOnPattern == null) {
          continue;
        }

        final nearest = _nearestStopInPattern(pattern, latitude, longitude);
        if (nearest == null) {
          continue;
        }

        final travelingForward =
            destinationOnPattern.stopSequence >= nearest.stopSequence;
        final forwardBonus = travelingForward ? 100000.0 : -100000.0;
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          nearest.latitude,
          nearest.longitude,
        );
        var score = forwardBonus - distance;
        score += _headingAlignmentBonus(
          pattern: pattern,
          fromStop: nearest,
          headingDegrees: headingDegrees,
          speedMps: speedMps,
        );
        if (score > bestScore) {
          bestScore = score;
          bestPattern = pattern;
        }
      }

      if (bestPattern != null) {
        return bestPattern;
      }
    }

    if (destinationStop != null && anchorStop != null) {
      return _pickPatternForTrip(
        candidateList,
        anchorStop: anchorStop,
        destinationStop: destinationStop,
        latitude: latitude,
        longitude: longitude,
        headingDegrees: headingDegrees,
        speedMps: speedMps,
      );
    }

    return candidateList.reduce(
      (a, b) => a.length >= b.length ? a : b,
    );
  }

  static List<TransitStop> _pickPatternForTrip(
    List<List<TransitStop>> patterns, {
    required TransitStop anchorStop,
    required TransitStop destinationStop,
    double? latitude,
    double? longitude,
    double? headingDegrees,
    double? speedMps,
  }) {
    List<TransitStop>? bestPattern;
    var bestScore = double.negativeInfinity;

    for (final pattern in patterns) {
      final anchorOnPattern = _findMatchingStop(pattern, anchorStop);
      final destinationOnPattern = _findMatchingStop(pattern, destinationStop);
      if (anchorOnPattern == null || destinationOnPattern == null) {
        continue;
      }

      final travelingForward =
          destinationOnPattern.stopSequence >= anchorOnPattern.stopSequence;
      final forwardBonus = travelingForward ? 100000.0 : -100000.0;
      var score = forwardBonus;

      if (latitude != null && longitude != null) {
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          anchorOnPattern.latitude,
          anchorOnPattern.longitude,
        );
        score -= distance;
      } else {
        score -= (destinationOnPattern.stopSequence - anchorOnPattern.stopSequence)
                .abs() *
            1000.0;
      }

      score += _headingAlignmentBonus(
        pattern: pattern,
        fromStop: anchorOnPattern,
        headingDegrees: headingDegrees,
        speedMps: speedMps,
      );

      if (score > bestScore) {
        bestScore = score;
        bestPattern = pattern;
      }
    }

    return bestPattern ?? patterns.first;
  }

  static double _headingAlignmentBonus({
    required List<TransitStop> pattern,
    required TransitStop fromStop,
    double? headingDegrees,
    double? speedMps,
  }) {
    if (!GeoHeadingUtils.shouldUseHeading(headingDegrees, speedMps)) {
      return 0;
    }

    final bearing = _bearingToNextStopOnPattern(pattern, fromStop);
    if (bearing == null) {
      return 0;
    }

    final delta = GeoHeadingUtils.headingDeltaDegrees(bearing, headingDegrees!);
    return (90 - delta.clamp(0, 90)) * 200;
  }

  static double? _bearingToNextStopOnPattern(
    List<TransitStop> pattern,
    TransitStop fromStop,
  ) {
    TransitStop? next;
    for (final stop in pattern) {
      if (stop.stopSequence == fromStop.stopSequence + 1) {
        next = stop;
        break;
      }
    }
    next ??= pattern
        .where((stop) => stop.stopSequence == fromStop.stopSequence - 1)
        .firstOrNull;
    if (next == null) {
      return null;
    }

    return Geolocator.bearingBetween(
      fromStop.latitude,
      fromStop.longitude,
      next.latitude,
      next.longitude,
    );
  }

  static bool _patternContainsStop(
    List<TransitStop> pattern,
    TransitStop stop,
  ) {
    return _findMatchingStop(pattern, stop) != null;
  }

  static TransitStop? _findMatchingStop(
    List<TransitStop> pattern,
    TransitStop stop,
  ) {
    for (final candidate in pattern) {
      if (GtfsStopNameUtils.namesMatch(candidate.stopName, stop.stopName)) {
        return candidate;
      }
    }
    return null;
  }

  static TransitStop? _nearestStopInPattern(
    List<TransitStop> pattern,
    double latitude,
    double longitude,
  ) {
    TransitStop? nearest;
    var nearestDistance = double.infinity;

    for (final stop in pattern) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        stop.latitude,
        stop.longitude,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = stop;
      }
    }

    return nearest;
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

    if (vehicleType != null) {
      return const [];
    }

    return const [
      TransitLineOption(
        lineName: TransitCatalog.allRoutesLine,
        displayLabel: TransitCatalog.allRoutesLine,
      ),
    ];
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

  /// Agency + full line name for favorites, e.g. `TTC · 1 · Line 1
  /// (Yonge-University)`. Falls back to the raw stored line ref when the route
  /// is not loaded from GTFS.
  String favoriteLineLabel({
    required String transitSystem,
    required String lineName,
  }) {
    final route = routeForTransitLine(
      transitSystem: transitSystem,
      lineName: lineName,
    );
    if (route != null) {
      return '$transitSystem · ${TransitLineOption.fromRoute(route).singleLineLabel}';
    }
    return '$transitSystem · $lineName';
  }

  /// Home-screen label: agency, route code, and long name when available.
  /// Example: `GO Transit - LW - Lakeshore West`.
  String selectedLineDisplayLabel({
    required String transitSystem,
    required String lineRef,
  }) {
    final route = routeForTransitLine(
      transitSystem: transitSystem,
      lineName: lineRef,
    );
    if (route != null) {
      final option = TransitLineOption.fromRoute(route);
      final parts = <String>[transitSystem, option.displayLabel];
      if (option.subtitle != null && option.subtitle!.isNotEmpty) {
        parts.add(option.subtitle!);
      }
      return parts.join(' - ');
    }
    return '$transitSystem · $lineRef';
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
    return filterStationsOnRoute(routeId: routeId, query: query)
        .map((station) => station.representativeStop)
        .toList(growable: false);
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
