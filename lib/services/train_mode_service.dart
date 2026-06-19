import 'package:geolocator/geolocator.dart';

import '../models/destination.dart';
import '../models/train_mode_snapshot.dart';
import '../models/transit_stop.dart';
import 'gtfs_service.dart';

class TrainModeService {
  TrainModeService(this._gtfsService);

  final GtfsService _gtfsService;

  TrainModeSnapshot evaluate({
    required Destination? destination,
    required double? latitude,
    required double? longitude,
    String? routeId,
  }) {
    if (destination == null || latitude == null || longitude == null) {
      return TrainModeSnapshot.inactive;
    }

    final detection = _gtfsService.detectAgencyFromDestination(destination.name);
    final resolvedRouteId = routeId ?? detection?.route?.routeId;
    if (resolvedRouteId == null) {
      return TrainModeSnapshot.inactive;
    }

    final route = _gtfsService.routeById(resolvedRouteId);
    final agency = route == null
        ? null
        : _gtfsService.agencyById(route.agencyId);
    final routeStops = _gtfsService.stopsForRoute(resolvedRouteId);
    if (route == null || agency == null || routeStops.length < 2) {
      return TrainModeSnapshot.inactive;
    }

    final destinationStation = getDestinationStation(
      destination: destination,
      routeId: resolvedRouteId,
    );
    final currentNearestStation = getCurrentNearestStation(
      latitude: latitude,
      longitude: longitude,
      routeId: resolvedRouteId,
    );

    if (destinationStation == null || currentNearestStation == null) {
      return TrainModeSnapshot.inactive;
    }

    final nextStation = getNextStation(
      currentNearestStation: currentNearestStation,
      destinationStation: destinationStation,
      routeId: resolvedRouteId,
    );
    final previousStation = getPreviousStation(
      currentNearestStation: currentNearestStation,
      destinationStation: destinationStation,
      routeId: resolvedRouteId,
    );
    final stationsRemaining = getStationsRemaining(
      currentNearestStation: currentNearestStation,
      destinationStation: destinationStation,
    );

    final status = stationsRemaining == 0
        ? 'At destination'
        : 'Approaching destination';

    return TrainModeSnapshot(
      isActive: true,
      agency: agency,
      route: route,
      destinationStation: destinationStation,
      currentNearestStation: currentNearestStation,
      previousStation: previousStation,
      nextStation: nextStation,
      stationsRemaining: stationsRemaining,
      status: status,
    );
  }

  TransitStop? getDestinationStation({
    required Destination destination,
    required String routeId,
  }) {
    return _gtfsService.findStopByName(
      destination.name,
      routeId: routeId,
    );
  }

  TransitStop? getCurrentNearestStation({
    required double latitude,
    required double longitude,
    required String routeId,
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

    return nearest;
  }

  TransitStop? getPreviousStation({
    required TransitStop currentNearestStation,
    required TransitStop destinationStation,
    required String routeId,
  }) {
    final routeStops = _sortedStops(routeId);
    final travelingForward =
        destinationStation.stopSequence >= currentNearestStation.stopSequence;
    final targetSequence = travelingForward
        ? currentNearestStation.stopSequence - 1
        : currentNearestStation.stopSequence + 1;

    for (final stop in routeStops) {
      if (stop.stopSequence == targetSequence) {
        return stop;
      }
    }

    return currentNearestStation;
  }

  TransitStop? getNextStation({
    required TransitStop currentNearestStation,
    required TransitStop destinationStation,
    required String routeId,
  }) {
    final routeStops = _sortedStops(routeId);
    final travelingForward =
        destinationStation.stopSequence >= currentNearestStation.stopSequence;
    final targetSequence = travelingForward
        ? currentNearestStation.stopSequence + 1
        : currentNearestStation.stopSequence - 1;

    for (final stop in routeStops) {
      if (stop.stopSequence == targetSequence) {
        return stop;
      }
    }

    return destinationStation;
  }

  int getStationsRemaining({
    required TransitStop currentNearestStation,
    required TransitStop destinationStation,
  }) {
    return (destinationStation.stopSequence - currentNearestStation.stopSequence)
        .abs();
  }

  List<TransitStop> _sortedStops(String routeId) {
    final routeStops = List<TransitStop>.from(
      _gtfsService.stopsForRoute(routeId),
    )..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return routeStops;
  }
}
