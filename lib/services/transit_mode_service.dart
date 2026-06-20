import 'package:geolocator/geolocator.dart';

import '../models/destination.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_stop.dart';
import 'gtfs_service.dart';

class TransitModeService {
  TransitModeService(this._gtfsService);

  final GtfsService _gtfsService;

  /// Max GPS distance to a route stop before we treat the user as off-route.
  static const defaultMaxStopProximityMeters = 1000;

  TransitModeSnapshot evaluate({
    required Destination? destination,
    required double? latitude,
    required double? longitude,
    String? routeId,
    int maxStopProximityMeters = defaultMaxStopProximityMeters,
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
    final currentStop = getCurrentStop(
      latitude: latitude,
      longitude: longitude,
      routeId: resolvedRouteId,
      maxProximityMeters: maxStopProximityMeters,
    );

    if (destinationStop == null || currentStop == null) {
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

  List<TransitStop> _sortedStops(String routeId) {
    final routeStops = List<TransitStop>.from(
      _gtfsService.stopsForRoute(routeId),
    )..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return routeStops;
  }
}
