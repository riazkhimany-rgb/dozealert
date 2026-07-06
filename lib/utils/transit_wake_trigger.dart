import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/transit_stop.dart';
import '../models/transit_vehicle_type.dart';
import 'gps_tracking_confidence.dart';
import 'rider_motion_rules.dart';
import 'transit_wake_tuning.dart';

/// Shared stop-based wake rules for foreground and background isolates.
class TransitWakeTrigger {
  const TransitWakeTrigger._();

  static bool shouldTrigger({
    required int stopsRemaining,
    required int wakeStopCount,
    required bool directionLocked,
    required bool hasEstablishedProgress,
    required double? alongRouteRemainingMeters,
    required double? offRouteMeters,
    required double accuracyMeters,
    required double? speedMps,
    required List<TransitStop> segmentStops,
    required TransitStop? currentStop,
    required TransitStop? destinationStop,
    TransitVehicleType? vehicleType,
    bool? activityInVehicle,
    bool? activityOnFoot,
  }) {
    if (!directionLocked || !hasEstablishedProgress) {
      return false;
    }

    if (stopsRemaining < 0) {
      return false;
    }

    final current = currentStop;
    final destination = destinationStop;
    if (current == null ||
        destination == null ||
        segmentStops.length < 2) {
      return false;
    }

    if (wakeStopCount == 0) {
      if (!hasReachedWakeStop(
        segmentStops: segmentStops,
        currentStop: current,
        wakeStop: destination,
        destinationStop: destination,
      )) {
        return false;
      }

      return isNearWakeStopAlongRoute(
        alongRouteRemainingMeters: alongRouteRemainingMeters,
        segmentStops: segmentStops,
        wakeStop: destination,
        destinationStop: destination,
        vehicleType: vehicleType,
      );
    }

    if (stopsRemaining > wakeStopCount) {
      return false;
    }

    final wakeStop = wakeStopInSegment(
      segmentStops: segmentStops,
      destinationStop: destination,
      wakeStopCount: wakeStopCount,
    );
    if (wakeStop == null) {
      return false;
    }

    if (!hasReachedWakeStop(
      segmentStops: segmentStops,
      currentStop: current,
      wakeStop: wakeStop,
      destinationStop: destination,
    )) {
      return false;
    }

    return isNearWakeStopAlongRoute(
      alongRouteRemainingMeters: alongRouteRemainingMeters,
      segmentStops: segmentStops,
      wakeStop: wakeStop,
      destinationStop: destination,
      vehicleType: vehicleType,
    );
  }

  /// Stop where the rider should get off for [wakeStopCount] before destination.
  static TransitStop? wakeStopInSegment({
    required List<TransitStop> segmentStops,
    required TransitStop destinationStop,
    required int wakeStopCount,
  }) {
    if (wakeStopCount <= 0) {
      return destinationStop;
    }

    if (segmentStops.length <= wakeStopCount) {
      return segmentStops.first;
    }

    final index = segmentStops.length - 1 - wakeStopCount;
    if (index < 0 || index >= segmentStops.length) {
      return null;
    }

    return segmentStops[index];
  }

  /// True when [currentStop] is at or past [wakeStop] along the segment.
  static bool hasReachedWakeStop({
    required List<TransitStop> segmentStops,
    required TransitStop currentStop,
    required TransitStop wakeStop,
    required TransitStop destinationStop,
  }) {
    final currentIndex = segmentStops.indexWhere(
      (stop) => stop.stopSequence == currentStop.stopSequence,
    );
    final wakeIndex = segmentStops.indexWhere(
      (stop) => stop.stopSequence == wakeStop.stopSequence,
    );
    if (currentIndex < 0 || wakeIndex < 0) {
      return false;
    }

    final travelingForward =
        destinationStop.stopSequence >= segmentStops.first.stopSequence;
    if (travelingForward) {
      return currentIndex >= wakeIndex;
    }

    return currentIndex <= wakeIndex;
  }

  /// True when GPS is physically near [wakeStop] along the route, not merely
  /// assigned to that stop by noisy sequence advancement.
  static bool isNearWakeStopAlongRoute({
    required double? alongRouteRemainingMeters,
    required List<TransitStop> segmentStops,
    required TransitStop wakeStop,
    required TransitStop destinationStop,
    TransitVehicleType? vehicleType,
  }) {
    if (alongRouteRemainingMeters == null) {
      return false;
    }

    final wakeToDestinationMeters = alongRouteMetersBetweenStops(
      segmentStops: segmentStops,
      fromStop: wakeStop,
      toStop: destinationStop,
      destinationStop: destinationStop,
    );
    if (wakeToDestinationMeters == null) {
      return false;
    }

    final buffer = TransitWakeTuning.approachBufferMeters(vehicleType);
    return alongRouteRemainingMeters <= wakeToDestinationMeters + buffer;
  }

  static double? alongRouteMetersBetweenStops({
    required List<TransitStop> segmentStops,
    required TransitStop fromStop,
    required TransitStop toStop,
    required TransitStop destinationStop,
  }) {
    final travelingForward =
        destinationStop.stopSequence >= segmentStops.first.stopSequence;
    final ordered = List<TransitStop>.from(segmentStops)
      ..sort(
        (a, b) => travelingForward
            ? a.stopSequence.compareTo(b.stopSequence)
            : b.stopSequence.compareTo(a.stopSequence),
      );

    final fromIndex = ordered.indexWhere(
      (stop) => stop.stopSequence == fromStop.stopSequence,
    );
    final toIndex = ordered.indexWhere(
      (stop) => stop.stopSequence == toStop.stopSequence,
    );
    if (fromIndex < 0 || toIndex < 0) {
      return null;
    }

    final start = math.min(fromIndex, toIndex);
    final end = math.max(fromIndex, toIndex);
    var total = 0.0;
    for (var index = start; index < end; index++) {
      final a = ordered[index];
      final b = ordered[index + 1];
      total += Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
    }
    return total;
  }

  /// Legacy approach-wake path — kept for tests; no longer used in production.
  static bool shouldTriggerApproachWake({
    required int stopsRemaining,
    required int wakeStopCount,
    required double? alongRouteRemainingMeters,
    required double? offRouteMeters,
    required double accuracyMeters,
    required double? speedMps,
    required List<TransitStop> segmentStops,
    required TransitStop? currentStop,
    required TransitStop? destinationStop,
    bool? activityInVehicle,
    bool? activityOnFoot,
  }) {
    if (wakeStopCount <= 0 || stopsRemaining != wakeStopCount + 1) {
      return false;
    }

    if (!RiderMotionRules.allowsApproachWake(
      useActivityRecognition: true,
      activityInVehicle: activityInVehicle,
      activityOnFoot: activityOnFoot,
      speedMps: speedMps,
    )) {
      return false;
    }

    if (!GpsTrackingConfidence.isHigh(
      directionLocked: true,
      offRouteMeters: offRouteMeters,
      accuracyMeters: accuracyMeters,
      speedMps: speedMps,
      inVehicle: RiderMotionRules.resolvesInVehicle(
        useActivityRecognition: true,
        activityInVehicle: activityInVehicle,
        speedMps: speedMps,
      ),
    )) {
      return false;
    }

    return false;
  }
}
