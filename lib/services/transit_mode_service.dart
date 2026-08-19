import 'package:geolocator/geolocator.dart';

import '../models/destination.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_stop.dart';
import '../models/transit_vehicle_type.dart';
import '../utils/transit_wake_tuning.dart';
import '../utils/along_route_smoother.dart';
import '../utils/gtfs_stop_name_utils.dart';
import '../utils/trip_pattern_validation.dart';
import 'gtfs_service.dart';
import 'route_geometry_service.dart';
import 'transit_trip_session.dart';

class TransitModeService {
  TransitModeService(
    this._gtfsService, [
    RouteGeometryService? routeGeometryService,
    TransitTripSession? tripSession,
  ]) : _routeGeometry = routeGeometryService ?? RouteGeometryService(),
       _tripSession = tripSession ?? TransitTripSession();

  final GtfsService _gtfsService;
  final RouteGeometryService _routeGeometry;
  final TransitTripSession _tripSession;
  final AlongRouteSmoother _alongRouteSmoother = AlongRouteSmoother();

  TransitTripSession get tripSession => _tripSession;

  void resetTripSession() {
    _tripSession.reset();
    _alongRouteSmoother.reset();
  }

  /// Max perpendicular distance from the route polyline before off-route.
  static const defaultMaxStopProximityMeters = 1000;

  /// Tighter radius for snapping GPS to a route stop (separate from wake distance).
  static const routeStopMatchMeters = 400;

  TransitModeSnapshot evaluate({
    required Destination? destination,
    required double? latitude,
    required double? longitude,
    String? routeId,
    int maxStopProximityMeters = defaultMaxStopProximityMeters,
    double? headingDegrees,
    double? speedMps,
    double? accuracyMeters,
    DateTime? fixTimestamp,
  }) {
    if (destination == null || latitude == null || longitude == null) {
      return TransitModeSnapshot.inactive;
    }

    final detection = _gtfsService.detectAgencyFromDestination(
      destination.name,
    );
    final resolvedRouteId = routeId ?? detection?.route?.routeId;
    if (resolvedRouteId == null) {
      return TransitModeSnapshot.inactive;
    }

    final route = _gtfsService.routeById(resolvedRouteId);
    final agency = route == null
        ? null
        : _gtfsService.agencyById(route.agencyId);
    if (route == null || agency == null) {
      return TransitModeSnapshot.inactive;
    }

    final destinationStopCandidate = getDestinationStop(
      destination: destination,
      routeId: resolvedRouteId,
    );
    if (destinationStopCandidate == null) {
      return TransitModeSnapshot.inactive;
    }

    final destinationKey =
        destination.stationKey ??
        GtfsStopNameUtils.stationDisplayName(destination.name);

    if (!_tripSession.isDirectionLocked && !_tripSession.isSeeded) {
      // Pass GPS context so the seed scores the correct direction on any
      // bidirectional route where the destination stop appears in both patterns
      // (buses, streetcars, subway, commuter rail). Without GPS the heuristic
      // may pick the wrong pattern and cause a false Wrong Direction warning.
      final seedPattern = _gtfsService.inferPatternKeyForRoute(
        resolvedRouteId,
        destinationStop: destinationStopCandidate,
        latitude: latitude,
        longitude: longitude,
        headingDegrees: headingDegrees,
        speedMps: speedMps,
      );
      if (seedPattern != null) {
        _tripSession.seedPatternKey(
          routeId: resolvedRouteId,
          destinationKey: destinationKey,
          patternKey: seedPattern,
        );
      }
    }

    var inferredPattern = _gtfsService.inferPatternKeyForRoute(
      resolvedRouteId,
      destinationStop: destinationStopCandidate,
      latitude: latitude,
      longitude: longitude,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
    );
    var patternKey = _tripSession.updateAndGetPatternKey(
      routeId: resolvedRouteId,
      destinationKey: destinationKey,
      inferredPatternKey: inferredPattern,
    );

    var routeStops = _gtfsService.stopsForRoute(
      resolvedRouteId,
      destinationStop: destinationStopCandidate,
      lockedPatternKey: patternKey,
      latitude: latitude,
      longitude: longitude,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
    );
    if (routeStops.length < 2) {
      return TransitModeSnapshot.inactive;
    }

    var destinationStop =
        _gtfsService.resolveStopAmongStops(
          destination: destination,
          stops: routeStops,
        ) ??
        destinationStopCandidate;

    final polylineStops = _stopsUpToDestination(
      routeStops: routeStops,
      destinationStop: destinationStop,
    );
    final polyline = _routeGeometry.buildPolyline(
      routeStops: polylineStops,
      destinationStop: destinationStop,
      shapePoints: _gtfsService.shapePointsForPattern(
        routeId: resolvedRouteId,
        patternKey: patternKey,
      ),
    );
    final projection = _routeGeometry.projectOnPolyline(
      polyline: polyline,
      latitude: latitude,
      longitude: longitude,
    );

    var currentStop = _resolveCurrentStop(
      polyline: polyline,
      projection: projection,
      destinationStop: destinationStop,
      routeId: resolvedRouteId,
      latitude: latitude,
      longitude: longitude,
      maxStopProximityMeters: maxStopProximityMeters,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
      patternStops: routeStops,
      vehicleType: route.vehicleType,
    );

    currentStop ??= _corridorFallbackStop(
      projection: projection,
      routeStops: routeStops,
      destinationStop: destinationStop,
    );

    if (currentStop == null) {
      return TransitModeSnapshot.inactive;
    }

    inferredPattern = _gtfsService.inferPatternKeyForRoute(
      resolvedRouteId,
      destinationStop: destinationStop,
      anchorStop: currentStop,
      latitude: latitude,
      longitude: longitude,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
    );
    patternKey = _tripSession.updateAndGetPatternKey(
      routeId: resolvedRouteId,
      destinationKey: destinationKey,
      inferredPatternKey: inferredPattern,
    );
    routeStops = _gtfsService.stopsForRoute(
      resolvedRouteId,
      destinationStop: destinationStop,
      anchorStop: currentStop,
      lockedPatternKey: patternKey,
      latitude: latitude,
      longitude: longitude,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
    );

    destinationStop =
        _gtfsService.resolveStopAmongStops(
          destination: destination,
          stops: routeStops,
        ) ??
        destinationStop;
    currentStop =
        _gtfsService.resolveStopAmongStops(
          destination: Destination(
            name: currentStop.stopName,
            latitude: currentStop.latitude,
            longitude: currentStop.longitude,
            stationKey: _gtfsService.stationKeyForStop(currentStop),
          ),
          stops: routeStops,
        ) ??
        currentStop;

    // routeStops already in scope — use private helpers to avoid extra GTFS lookups.
    final nextStop = _nextStopFrom(
      patternStops: routeStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );
    final previousStop = _previousStopFrom(
      patternStops: routeStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );
    final stopsRemaining = _hopsToDestination(
      patternStops: routeStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );

    double? alongRouteRemainingMeters;
    double? offRouteMeters;
    if (projection != null) {
      offRouteMeters = projection.offRouteMeters;
      final rawAlong = _routeGeometry.alongRouteRemainingMeters(
        polyline: polyline,
        projection: projection,
        destinationStop: destinationStop,
      );
      if (rawAlong != null) {
        final timestamp = fixTimestamp ?? DateTime.now();
        var remaining = accuracyMeters != null && accuracyMeters > 0
            ? _alongRouteSmoother.smooth(
                alongRouteMeters: rawAlong,
                accuracyMeters: accuracyMeters,
                timestamp: timestamp,
                speedMps: speedMps,
              )
            : rawAlong;
        // At the destination stop, crow-flies is more trustworthy than a
        // shape hinterland remaining (often 1–3 km on GO rail).
        if (stopsRemaining == 0) {
          final haversine = Geolocator.distanceBetween(
            latitude,
            longitude,
            destinationStop.latitude,
            destinationStop.longitude,
          );
          if (haversine < remaining) {
            remaining = haversine;
          }
        }
        alongRouteRemainingMeters = remaining;
      }
    }

    final validation = validateTripOnPattern(
      pattern: routeStops,
      current: currentStop,
      destination: destinationStop,
      patternKey: patternKey,
      directionLocked: _tripSession.isDirectionLocked,
      pendingPatternKey: _tripSession.pendingPatternKey,
      alongRouteRemainingMeters: alongRouteRemainingMeters,
    );

    final status = stopsRemaining == 0
        ? 'At destination'
        : 'Approaching destination';

    return TransitModeSnapshot(
      isActive: true,
      agency: agency,
      route: route,
      vehicleType: route.vehicleType,
      destinationStop: destinationStop,
      currentStop: currentStop,
      previousStop: previousStop,
      nextStop: nextStop,
      stopsRemaining: stopsRemaining,
      alongRouteRemainingMeters: alongRouteRemainingMeters,
      offRouteMeters: offRouteMeters,
      status: status,
      tripConcern: validation.concern,
      directionLabel: validation.directionLabel,
      directionLocked: _tripSession.isDirectionLocked,
      directionConfirming:
          _tripSession.hasPendingDirection && !_tripSession.isDirectionLocked,
    );
  }

  TransitStop? getDestinationStop({
    required Destination destination,
    required String routeId,
  }) {
    return _gtfsService.resolveStopAmongStops(
      destination: destination,
      stops: _gtfsService.stopsForRoute(routeId),
    );
  }

  /// Seeds route direction from the picked stop before the first GPS fix arrives.
  void seedDirectionFromDestination({
    required Destination destination,
    required String routeId,
  }) {
    if (_tripSession.isDirectionLocked || _tripSession.isSeeded) {
      return;
    }

    final destinationStop = getDestinationStop(
      destination: destination,
      routeId: routeId,
    );
    if (destinationStop == null) {
      return;
    }

    final destinationKey =
        destination.stationKey ??
        GtfsStopNameUtils.stationDisplayName(destination.name);
    final seedPattern = _gtfsService.inferPatternKeyForRoute(
      routeId,
      destinationStop: destinationStop,
    );
    if (seedPattern == null) {
      return;
    }

    _tripSession.seedPatternKey(
      routeId: routeId,
      destinationKey: destinationKey,
      patternKey: seedPattern,
    );
  }

  /// True when [destination] resolves to a stop on a known GTFS route.
  bool isTransitTrackableDestination(
    Destination destination, {
    String? routeId,
  }) {
    final resolvedRouteId =
        routeId ??
        _gtfsService
            .detectAgencyFromDestination(destination.name)
            ?.route
            ?.routeId ??
        _gtfsService
            .detectAgencyFromDestinationAt(
              destinationName: destination.name,
              latitude: destination.latitude,
              longitude: destination.longitude,
            )
            ?.route
            ?.routeId;
    if (resolvedRouteId == null) {
      return false;
    }

    return getDestinationStop(
          destination: destination,
          routeId: resolvedRouteId,
        ) !=
        null;
  }

  TransitStop? getCurrentStop({
    required double latitude,
    required double longitude,
    required String routeId,
    required int maxProximityMeters,
    TransitStop? destinationStop,
  }) {
    final routeStops = _gtfsService.stopsForRoute(
      routeId,
      destinationStop: destinationStop,
      latitude: latitude,
      longitude: longitude,
      lockedPatternKey: _tripSession.lockedPatternKey,
    );
    if (routeStops.isEmpty) {
      return null;
    }

    final candidates = <TransitStop>[];
    for (final stop in routeStops) {
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

    if (destinationStop != null && candidates.length > 1) {
      final travelingForward =
          destinationStop.stopSequence >= candidates.first.stopSequence;
      candidates.sort(
        (a, b) => travelingForward
            ? a.stopSequence.compareTo(b.stopSequence)
            : b.stopSequence.compareTo(a.stopSequence),
      );
      return candidates.first;
    }

    TransitStop? nearest;
    var nearestDistance = double.infinity;

    for (final stop in candidates) {
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

  /// Rebuilds an active snapshot after [currentStop] was adjusted downstream.
  TransitModeSnapshot rebuildSnapshotWithCurrentStop({
    required TransitModeSnapshot snapshot,
    required TransitStop currentStop,
    required String routeId,
  }) {
    final destinationStop = snapshot.destinationStop;
    if (!snapshot.isActive || destinationStop == null) {
      return snapshot;
    }

    final patternStops = _sortedStops(
      routeId,
      destinationStop: destinationStop,
      anchorStop: currentStop,
      lockedPatternKey: _tripSession.lockedPatternKey,
    );
    final nextStop = _nextStopFrom(
      patternStops: patternStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );
    final previousStop = _previousStopFrom(
      patternStops: patternStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );
    final stopsRemaining = _hopsToDestination(
      patternStops: patternStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );

    final status = stopsRemaining == 0
        ? 'At destination'
        : 'Approaching destination';

    return TransitModeSnapshot(
      isActive: true,
      agency: snapshot.agency,
      route: snapshot.route,
      vehicleType: snapshot.vehicleType,
      destinationStop: destinationStop,
      currentStop: currentStop,
      previousStop: previousStop,
      nextStop: nextStop,
      stopsRemaining: stopsRemaining,
      alongRouteRemainingMeters: snapshot.alongRouteRemainingMeters,
      offRouteMeters: snapshot.offRouteMeters,
      status: status,
      tripConcern: snapshot.tripConcern,
      directionLabel: snapshot.directionLabel,
      directionLocked: snapshot.directionLocked,
      directionConfirming: snapshot.directionConfirming,
    );
  }

  List<TransitStop> routeStopsFor(
    String routeId, {
    TransitStop? destinationStop,
    TransitStop? anchorStop,
    double? latitude,
    double? longitude,
    String? lockedPatternKey,
  }) => _sortedStops(
    routeId,
    destinationStop: destinationStop,
    anchorStop: anchorStop,
    latitude: latitude,
    longitude: longitude,
    lockedPatternKey: lockedPatternKey ?? _tripSession.lockedPatternKey,
  );

  /// Measures a fixed wake target using the same GTFS shape/polyline as the
  /// live along-route remaining distance.
  double? distanceBetweenStopsAlongRoute({
    required String routeId,
    required List<TransitStop> segmentStops,
    required TransitStop fromStop,
    required TransitStop destinationStop,
    String? lockedPatternKey,
  }) {
    if (segmentStops.isEmpty) {
      return null;
    }
    final patternKey = lockedPatternKey ?? _tripSession.lockedPatternKey;
    final shapePoints = _gtfsService.shapePointsForPattern(
      routeId: routeId,
      patternKey: patternKey,
    );
    var polyline = _routeGeometry.buildPolyline(
      routeStops: segmentStops,
      destinationStop: destinationStop,
      shapePoints: shapePoints,
    );
    var distance = _routeGeometry.distanceBetweenStopsAlongRoute(
      polyline: polyline,
      fromStop: fromStop,
      toStop: destinationStop,
    );
    if (distance == null && shapePoints != null) {
      polyline = _routeGeometry.buildPolyline(
        routeStops: segmentStops,
        destinationStop: destinationStop,
      );
      distance = _routeGeometry.distanceBetweenStopsAlongRoute(
        polyline: polyline,
        fromStop: fromStop,
        toStop: destinationStop,
      );
    }
    return distance;
  }

  List<TransitStop> _stopsUpToDestination({
    required List<TransitStop> routeStops,
    required TransitStop destinationStop,
  }) {
    final sorted = List<TransitStop>.from(routeStops)
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    final travelingForward =
        destinationStop.stopSequence >= sorted.first.stopSequence;
    final segment =
        sorted.where((stop) {
          if (travelingForward) {
            return stop.stopSequence <= destinationStop.stopSequence;
          }
          return stop.stopSequence >= destinationStop.stopSequence;
        }).toList()..sort(
          (a, b) => travelingForward
              ? a.stopSequence.compareTo(b.stopSequence)
              : b.stopSequence.compareTo(a.stopSequence),
        );
    return segment.length >= 2 ? segment : routeStops;
  }

  TransitStop? _resolveCurrentStop({
    required RoutePolyline polyline,
    required RouteProjection? projection,
    required TransitStop destinationStop,
    required String routeId,
    required double latitude,
    required double longitude,
    required int maxStopProximityMeters,
    double? headingDegrees,
    double? speedMps,
    List<TransitStop>? patternStops,
    TransitVehicleType? vehicleType,
  }) {
    final snapTolerance = TransitWakeTuning.stopSnapAlongToleranceMeters(
      vehicleType,
    );
    if (projection != null) {
      if (projection.offRouteMeters <= maxStopProximityMeters) {
        final matched = _routeGeometry.matchCurrentStop(
          polyline: polyline,
          projection: projection,
          destinationStop: destinationStop,
          maxOffRouteMeters: maxStopProximityMeters,
          headingDegrees: headingDegrees,
          speedMps: speedMps,
          stopSnapAlongToleranceMeters: snapTolerance,
        );
        if (matched != null) {
          if (patternStops != null) {
            return _gtfsService.resolveStopAmongStops(
                  destination: Destination(
                    name: matched.stopName,
                    latitude: matched.latitude,
                    longitude: matched.longitude,
                    stationKey: _gtfsService.stationKeyForStop(matched),
                  ),
                  stops: patternStops,
                ) ??
                matched;
          }
          return matched;
        }

        final behind = _routeGeometry.bestStopAtOrBehindProjection(
          polyline: polyline,
          projection: projection,
        );
        if (behind != null && patternStops != null) {
          return _gtfsService.resolveStopAmongStops(
                destination: Destination(
                  name: behind.stopName,
                  latitude: behind.latitude,
                  longitude: behind.longitude,
                  stationKey: _gtfsService.stationKeyForStop(behind),
                ),
                stops: patternStops,
              ) ??
              behind;
        }
        return behind;
      }

      if (projection.offRouteMeters <= defaultMaxStopProximityMeters) {
        final behind = _routeGeometry.bestStopAtOrBehindProjection(
          polyline: polyline,
          projection: projection,
        );
        if (behind != null) {
          if (patternStops != null) {
            return _gtfsService.resolveStopAmongStops(
                  destination: Destination(
                    name: behind.stopName,
                    latitude: behind.latitude,
                    longitude: behind.longitude,
                    stationKey: _gtfsService.stationKeyForStop(behind),
                  ),
                  stops: patternStops,
                ) ??
                behind;
          }
          return behind;
        }
      }
    }

    if (projection == null) {
      final snapped = getCurrentStop(
        latitude: latitude,
        longitude: longitude,
        routeId: routeId,
        maxProximityMeters: maxStopProximityMeters,
        destinationStop: destinationStop,
      );
      if (snapped != null && patternStops != null) {
        return _gtfsService.resolveStopAmongStops(
              destination: Destination(
                name: snapped.stopName,
                latitude: snapped.latitude,
                longitude: snapped.longitude,
                stationKey: _gtfsService.stationKeyForStop(snapped),
              ),
              stops: patternStops,
            ) ??
            snapped;
      }
      return snapped;
    }

    return null;
  }

  TransitStop? _corridorFallbackStop({
    required RouteProjection? projection,
    required List<TransitStop> routeStops,
    required TransitStop destinationStop,
  }) {
    if (projection == null ||
        projection.offRouteMeters > defaultMaxStopProximityMeters) {
      return null;
    }

    return _gtfsService.resolveCurrentOnPattern(
      latitude: projection.latitude,
      longitude: projection.longitude,
      pattern: routeStops,
      maxProximityMeters: routeStopMatchMeters,
      destinationOnPattern: destinationStop,
    );
  }

  TransitStop? getPreviousStop({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required String routeId,
    double? latitude,
    double? longitude,
    String? lockedPatternKey,
  }) {
    final routeStops = _sortedStops(
      routeId,
      destinationStop: destinationStop,
      anchorStop: currentStop,
      latitude: latitude,
      longitude: longitude,
      lockedPatternKey: lockedPatternKey,
    );
    return _previousStopFrom(
      patternStops: routeStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );
  }

  TransitStop? getNextStop({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required String routeId,
    double? latitude,
    double? longitude,
    String? lockedPatternKey,
  }) {
    final routeStops = _sortedStops(
      routeId,
      destinationStop: destinationStop,
      anchorStop: currentStop,
      latitude: latitude,
      longitude: longitude,
      lockedPatternKey: lockedPatternKey,
    );
    return _nextStopFrom(
      patternStops: routeStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
    );
  }

  /// Number of stops between [currentStop] and [destinationStop], counted by
  /// actual hops in [patternStops] rather than raw sequence difference.
  ///
  /// Prefer passing [patternStops] (the sorted route stops already in memory)
  /// so the count is accurate for feeds that use non-consecutive sequences
  /// (e.g. step-10 or step-100 numbering). Falls back to sequence diff when
  /// no pattern is available.
  int getStopsRemaining({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    List<TransitStop>? patternStops,
  }) {
    if (patternStops != null && patternStops.isNotEmpty) {
      return _hopsToDestination(
        patternStops: patternStops,
        currentStop: currentStop,
        destinationStop: destinationStop,
      );
    }
    return (destinationStop.stopSequence - currentStop.stopSequence).abs();
  }

  /// Count the number of stop-hops from [currentStop] to [destinationStop]
  /// using the sorted [patternStops] list. Returns 0 when current == dest.
  ///
  /// This is the single source of truth for stops-remaining on both the
  /// foreground and background paths, replacing the old sequence-diff formula
  /// that broke for GTFS feeds with non-consecutive stop_sequence values.
  int _hopsToDestination({
    required List<TransitStop> patternStops,
    required TransitStop currentStop,
    required TransitStop destinationStop,
  }) {
    final forward = destinationStop.stopSequence >= currentStop.stopSequence;
    var count = 0;
    for (final stop in patternStops) {
      final seq = stop.stopSequence;
      if (forward) {
        if (seq >= currentStop.stopSequence &&
            seq <= destinationStop.stopSequence) {
          count++;
        }
      } else {
        if (seq <= currentStop.stopSequence &&
            seq >= destinationStop.stopSequence) {
          count++;
        }
      }
    }
    // count includes both endpoints; subtract 1 so at-destination == 0.
    return (count - 1).clamp(0, patternStops.length);
  }

  /// Returns the adjacent stop immediately BEFORE [currentStop] in travel
  /// direction — i.e. the stop that was just passed.
  ///
  /// Works for feeds with non-consecutive stop_sequence values by finding the
  /// nearest sequence that is strictly less-than (forward) or greater-than
  /// (backward) the current stop.
  TransitStop _previousStopFrom({
    required List<TransitStop> patternStops,
    required TransitStop currentStop,
    required TransitStop destinationStop,
  }) {
    final forward = destinationStop.stopSequence >= currentStop.stopSequence;
    if (forward) {
      // patternStops sorted ascending — last stop with seq < current.seq
      for (final stop in patternStops.reversed) {
        if (stop.stopSequence < currentStop.stopSequence) return stop;
      }
    } else {
      // traveling backward — first stop with seq > current.seq
      for (final stop in patternStops) {
        if (stop.stopSequence > currentStop.stopSequence) return stop;
      }
    }
    return currentStop;
  }

  /// Returns the adjacent stop immediately AFTER [currentStop] in travel
  /// direction — i.e. the next stop coming up.
  ///
  /// Works for feeds with non-consecutive stop_sequence values by finding the
  /// nearest sequence that is strictly greater-than (forward) or less-than
  /// (backward) the current stop, bounded by [destinationStop].
  TransitStop _nextStopFrom({
    required List<TransitStop> patternStops,
    required TransitStop currentStop,
    required TransitStop destinationStop,
  }) {
    final forward = destinationStop.stopSequence >= currentStop.stopSequence;
    if (forward) {
      for (final stop in patternStops) {
        if (stop.stopSequence > currentStop.stopSequence &&
            stop.stopSequence <= destinationStop.stopSequence) {
          return stop;
        }
      }
    } else {
      for (final stop in patternStops.reversed) {
        if (stop.stopSequence < currentStop.stopSequence &&
            stop.stopSequence >= destinationStop.stopSequence) {
          return stop;
        }
      }
    }
    return destinationStop;
  }

  /// Stops from [currentStop] through [destinationStop] along the route, inclusive.
  List<TransitStop> getStopsFromCurrentToDestination({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required String routeId,
    double? latitude,
    double? longitude,
    String? lockedPatternKey,
  }) {
    final routeStops = _sortedStops(
      routeId,
      destinationStop: destinationStop,
      anchorStop: currentStop,
      latitude: latitude,
      longitude: longitude,
      lockedPatternKey: lockedPatternKey ?? _tripSession.lockedPatternKey,
    );
    final travelingForward =
        destinationStop.stopSequence >= currentStop.stopSequence;

    final segment = routeStops.where((stop) {
      if (travelingForward) {
        return stop.stopSequence >= currentStop.stopSequence &&
            stop.stopSequence <= destinationStop.stopSequence;
      }
      return stop.stopSequence <= currentStop.stopSequence &&
          stop.stopSequence >= destinationStop.stopSequence;
    }).toList();

    segment.sort(
      (a, b) => travelingForward
          ? a.stopSequence.compareTo(b.stopSequence)
          : b.stopSequence.compareTo(a.stopSequence),
    );
    return segment;
  }

  List<TransitStop> _sortedStops(
    String routeId, {
    TransitStop? destinationStop,
    TransitStop? anchorStop,
    double? latitude,
    double? longitude,
    String? lockedPatternKey,
  }) {
    final routeStops = List<TransitStop>.from(
      _gtfsService.stopsForRoute(
        routeId,
        destinationStop: destinationStop,
        anchorStop: anchorStop,
        latitude: latitude,
        longitude: longitude,
        lockedPatternKey: lockedPatternKey ?? _tripSession.lockedPatternKey,
      ),
    )..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return routeStops;
  }
}
