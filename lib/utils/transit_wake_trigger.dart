import '../models/transit_stop.dart';
import 'gps_tracking_confidence.dart';
import 'rider_motion_rules.dart';

/// Shared stop-based wake rules for foreground and background isolates.
class TransitWakeTrigger {
  const TransitWakeTrigger._();

  static const approachBufferMeters = 250.0;
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

    if (stopsRemaining <= wakeStopCount) {
      return true;
    }

    if (wakeStopCount == 0 &&
        stopsRemaining == 1 &&
        offRouteMeters != null &&
        offRouteMeters <= onRouteSnapMeters) {
      return true;
    }

    return shouldTriggerApproachWake(
      stopsRemaining: stopsRemaining,
      wakeStopCount: wakeStopCount,
      alongRouteRemainingMeters: alongRouteRemainingMeters,
      offRouteMeters: offRouteMeters,
      accuracyMeters: accuracyMeters,
      speedMps: speedMps,
      segmentStops: segmentStops,
      currentStop: currentStop,
      destinationStop: destinationStop,
      activityInVehicle: activityInVehicle,
      activityOnFoot: activityOnFoot,
    );
  }

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
        activityInVehicle: activityInVehicle,
        speedMps: speedMps,
      ),
    )) {
      return false;
    }

    final alongRemaining = alongRouteRemainingMeters;
    final current = currentStop;
    final destination = destinationStop;
    if (alongRemaining == null ||
        current == null ||
        destination == null ||
        segmentStops.length < 2) {
      return false;
    }

    final wakeThresholdMeters = _metersToWakeThresholdStop(
      segmentStops: segmentStops,
      currentStop: current,
      destinationStop: destination,
      wakeStopCount: wakeStopCount,
    );
    if (wakeThresholdMeters == null) {
      return false;
    }

    return alongRemaining <= wakeThresholdMeters + approachBufferMeters;
  }

  static double? _metersToWakeThresholdStop({
    required List<TransitStop> segmentStops,
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required int wakeStopCount,
  }) {
    final currentIndex = segmentStops.indexWhere(
      (stop) => stop.stopSequence == currentStop.stopSequence,
    );
    final destinationIndex = segmentStops.indexWhere(
      (stop) => stop.stopSequence == destinationStop.stopSequence,
    );
    if (currentIndex < 0 || destinationIndex < 0) {
      return null;
    }

    final wakeIndex = destinationIndex +
        (destinationIndex >= currentIndex ? -wakeStopCount : wakeStopCount);
    if (wakeIndex < 0 || wakeIndex >= segmentStops.length) {
      return null;
    }

    var meters = 0.0;
    final step = destinationIndex >= currentIndex ? 1 : -1;
    for (var index = currentIndex; index != wakeIndex; index += step) {
      final nextIndex = index + step;
      if (nextIndex < 0 || nextIndex >= segmentStops.length) {
        return null;
      }
      final from = segmentStops[index];
      final to = segmentStops[nextIndex];
      meters += _segmentLengthMeters(from, to);
    }

    return meters;
  }

  static double _segmentLengthMeters(TransitStop from, TransitStop to) {
    final latDelta = (to.latitude - from.latitude).abs();
    final lonDelta = (to.longitude - from.longitude).abs();
    return (latDelta + lonDelta) * 111_000;
  }
}
