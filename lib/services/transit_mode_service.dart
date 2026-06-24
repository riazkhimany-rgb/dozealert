import 'package:geolocator/geolocator.dart';

import '../models/destination.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_stop.dart';
import 'gtfs_service.dart';
import 'route_geometry_service.dart';

class TransitModeService {
  TransitModeService(
    this._gtfsService, [
    RouteGeometryService? routeGeometryService,
  ]) : _routeGeometry = routeGeometryService ?? RouteGeometryService();

  final GtfsService _gtfsService;
  final RouteGeometryService _routeGeometry;

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
  }) {
    if (destination == null || latitude == null || longitude == null) {
      return TransitModeSnapshot.inactive;
    }

    final detection = _gtfsService.detectAgencyFromDestination(destination.name);
    final resolvedRouteId = routeId ?? detection?.route?.routeId;
    if (resolvedRouteId == null) {
      return TransitModeSnapshot.inactive;
    }

    final route = _gtfsService.routeById(resolvedRouteId);
    final agency = route == null
        ? null
        : _gtfsService.agencyById(route.agencyId);
    final routeStops = _gtfsService.stopsForRoute(resolvedRouteId);
    if (route == null || agency == null || routeStops.length < 2) {
      return TransitModeSnapshot.inactive;
    }

    final destinationStop = getDestinationStop(
      destination: destination,
      routeId: resolvedRouteId,
    );
    if (destinationStop == null) {
      return TransitModeSnapshot.inactive;
    }

    final polyline = _routeGeometry.buildPolyline(
      routeStops: routeStops,
      destinationStop: destinationStop,
    );
    final projection = _routeGeometry.projectOnPolyline(
      polyline: polyline,
      latitude: latitude,
      longitude: longitude,
    );

    final currentStop = projection == null
        ? getCurrentStop(
            latitude: latitude,
            longitude: longitude,
            routeId: resolvedRouteId,
            maxProximityMeters: maxStopProximityMeters,
          )
        : _routeGeometry.matchCurrentStop(
            polyline: polyline,
            projection: projection,
            destinationStop: destinationStop,
            maxOffRouteMeters: maxStopProximityMeters,
            headingDegrees: headingDegrees,
            speedMps: speedMps,
          ) ??
            getCurrentStop(
              latitude: latitude,
              longitude: longitude,
              routeId: resolvedRouteId,
              maxProximityMeters: maxStopProximityMeters,
            );

    if (currentStop == null) {
      return TransitModeSnapshot.inactive;
    }

    final nextStop = getNextStop(
      currentStop: currentStop,
      destinationStop: destinationStop,
      routeId: resolvedRouteId,
    );
    final previousStop = getPreviousStop(
      currentStop: currentStop,
      destinationStop: destinationStop,
      routeId: resolvedRouteId,
    );
    final stopsRemaining = getStopsRemaining(
      currentStop: currentStop,
      destinationStop: destinationStop,
    );

    double? alongRouteRemainingMeters;
    double? offRouteMeters;
    if (projection != null) {
      offRouteMeters = projection.offRouteMeters;
      alongRouteRemainingMeters = _routeGeometry.alongRouteRemainingMeters(
        polyline: polyline,
        projection: projection,
        destinationStop: destinationStop,
      );
    }

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
    );
  }

  TransitStop? getDestinationStop({
    required Destination destination,
    required String routeId,
  }) {
    return _gtfsService.findStopByName(
      destination.name,
      routeId: routeId,
    );
  }

  TransitStop? getCurrentStop({
    required double latitude,
    required double longitude,
    required String routeId,
    required int maxProximityMeters,
  }) {
    final routeStops = _gtfsService.stopsForRoute(routeId);
    if (routeStops.isEmpty) {
      return null;
    }

    TransitStop? nearest;
    var nearestDistance = double.infinity;

    for (final stop in routeStops) {
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

    if (nearest == null || nearestDistance > maxProximityMeters) {
      return null;
    }

    return nearest;
  }

  TransitStop? getPreviousStop({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required String routeId,
  }) {
    final routeStops = _sortedStops(routeId);
    final travelingForward =
        destinationStop.stopSequence >= currentStop.stopSequence;
    final targetSequence = travelingForward
        ? currentStop.stopSequence - 1
        : currentStop.stopSequence + 1;

    for (final stop in routeStops) {
      if (stop.stopSequence == targetSequence) {
        return stop;
      }
    }

    return currentStop;
  }

  TransitStop? getNextStop({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required String routeId,
  }) {
    final routeStops = _sortedStops(routeId);
    final travelingForward =
        destinationStop.stopSequence >= currentStop.stopSequence;
    final targetSequence = travelingForward
        ? currentStop.stopSequence + 1
        : currentStop.stopSequence - 1;

    for (final stop in routeStops) {
      if (stop.stopSequence == targetSequence) {
        return stop;
      }
    }

    return destinationStop;
  }

  int getStopsRemaining({
    required TransitStop currentStop,
    required TransitStop destinationStop,
  }) {
    return (destinationStop.stopSequence - currentStop.stopSequence).abs();
  }

  /// Stops from [currentStop] through [destinationStop] along the route, inclusive.
  List<TransitStop> getStopsFromCurrentToDestination({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required String routeId,
  }) {
    final routeStops = _sortedStops(routeId);
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

  List<TransitStop> _sortedStops(String routeId) {
    final routeStops = List<TransitStop>.from(
      _gtfsService.stopsForRoute(routeId),
    )..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return routeStops;
  }
}
