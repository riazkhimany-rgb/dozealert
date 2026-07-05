import '../models/transit_stop.dart';
import 'gps_tracking_confidence.dart';
import 'rider_motion_rules.dart';

/// Shared stop-based wake rules for foreground and background isolates.
class TransitWakeTrigger {
  const TransitWakeTrigger._();

  static const onRouteSnapMeters = 400.0;

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
    bool? activityInVehicle,
    bool? activityOnFoot,
  }) {
    if (!directionLocked || !hasEstablishedProgress) {
      return false;
    }

    if (stopsRemaining < 0) {
      return false;
    }

    if (wakeStopCount == 0) {
      if (stopsRemaining == 0) {
        return true;
      }

      if (stopsRemaining == 1 &&
          offRouteMeters != null &&
          offRouteMeters <= onRouteSnapMeters) {
        return true;
      }

      return false;
    }

    if (stopsRemaining > wakeStopCount) {
      return false;
    }

    final current = currentStop;
    final destination = destinationStop;
    if (current == null ||
        destination == null ||
        segmentStops.length < 2) {
      return stopsRemaining <= wakeStopCount;
    }

    final wakeStop = wakeStopInSegment(
      segmentStops: segmentStops,
      destinationStop: destination,
      wakeStopCount: wakeStopCount,
    );
    if (wakeStop == null) {
      return stopsRemaining <= wakeStopCount;
    }

    return hasReachedWakeStop(
      segmentStops: segmentStops,
      currentStop: current,
      wakeStop: wakeStop,
      destinationStop: destination,
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
      return null;
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
