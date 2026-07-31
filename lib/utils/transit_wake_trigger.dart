import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/transit_wake_plan.dart';
import '../models/transit_stop.dart';
import '../models/transit_vehicle_type.dart';
import '../services/transit_mode_service.dart';
import 'gps_tracking_confidence.dart';
import 'rider_motion_rules.dart';
import 'transit_wake_tuning.dart';

enum TransitWakeDecisionReason {
  notReady,
  tripConcern,
  beforeWakeStop,
  armedWaitingForDistance,
  armedWaitingForGpsGrace,
  confirmedByDistance,
  recoveredAfterStopJump,
  confirmedByPoorGpsFallback,
}

class TransitWakeDecision {
  const TransitWakeDecision({
    required this.shouldTrigger,
    required this.isArmed,
    required this.reason,
  });

  final bool shouldTrigger;
  final bool isArmed;
  final TransitWakeDecisionReason reason;
}

/// Shared stop-based wake rules for foreground and background isolates.
class TransitWakeTrigger {
  const TransitWakeTrigger._();

  static const maxUsableAccuracyMeters = 150.0;
  static const minStableArmFixes = 2;

  /// Stop-first wake evaluation against a fixed, non-shrinking trip plan.
  ///
  /// Stop progress arms the wake; usable along-route distance confirms it.
  /// When route GPS is unavailable, stable stop evidence may confirm it after
  /// the vehicle-specific grace period.
  static TransitWakeDecision evaluatePlan({
    required TransitWakePlan plan,
    required bool directionLocked,
    required bool hasEstablishedProgress,
    required bool hasTripConcern,
    required TransitStop? currentStop,
    required double? alongRouteRemainingMeters,
    required double? offRouteMeters,
    required double accuracyMeters,
    required bool gpsStale,
    required DateTime? armedAt,
    required int armStableFixes,
    DateTime? now,
  }) {
    if (!plan.isValid || !directionLocked || !hasEstablishedProgress) {
      return const TransitWakeDecision(
        shouldTrigger: false,
        isArmed: false,
        reason: TransitWakeDecisionReason.notReady,
      );
    }
    if (hasTripConcern) {
      return const TransitWakeDecision(
        shouldTrigger: false,
        isArmed: false,
        reason: TransitWakeDecisionReason.tripConcern,
      );
    }

    final current = currentStop;
    final reachedWakeStop =
        current != null && plan.hasReachedWakeStop(current.stopSequence);
    final isArmed = armedAt != null || reachedWakeStop;
    if (!isArmed) {
      return const TransitWakeDecision(
        shouldTrigger: false,
        isArmed: false,
        reason: TransitWakeDecisionReason.beforeWakeStop,
      );
    }

    final hasUsableRouteDistance =
        !gpsStale &&
        alongRouteRemainingMeters != null &&
        accuracyMeters > 0 &&
        accuracyMeters <= maxUsableAccuracyMeters &&
        offRouteMeters != null &&
        offRouteMeters <= TransitModeService.routeStopMatchMeters;
    if (hasUsableRouteDistance) {
      final buffer = TransitWakeTuning.approachBufferMeters(
        plan.vehicleType,
        wakeStopCount: plan.wakeStopCount,
      );
      final jumpedToDestination =
          current?.stopSequence == plan.destinationStopSequence &&
          plan.wakeStopSequence != plan.destinationStopSequence;
      // Stop-jump recovery may only confirm near the destination itself — not
      // the full wake-to-destination span (which can be 1km+ on rail).
      final threshold = jumpedToDestination
          ? buffer
          : plan.wakeToDestinationMeters + buffer;
      if (alongRouteRemainingMeters <= threshold) {
        return TransitWakeDecision(
          shouldTrigger: true,
          isArmed: true,
          reason: jumpedToDestination
              ? TransitWakeDecisionReason.recoveredAfterStopJump
              : TransitWakeDecisionReason.confirmedByDistance,
        );
      }
      return const TransitWakeDecision(
        shouldTrigger: false,
        isArmed: true,
        reason: TransitWakeDecisionReason.armedWaitingForDistance,
      );
    }

    final effectiveNow = now ?? DateTime.now();
    final grace = TransitWakeTuning.poorGpsGracePeriod(plan.vehicleType);
    if (armedAt != null &&
        armStableFixes >= minStableArmFixes &&
        effectiveNow.difference(armedAt) >= grace) {
      return const TransitWakeDecision(
        shouldTrigger: true,
        isArmed: true,
        reason: TransitWakeDecisionReason.confirmedByPoorGpsFallback,
      );
    }

    return const TransitWakeDecision(
      shouldTrigger: false,
      isArmed: true,
      reason: TransitWakeDecisionReason.armedWaitingForGpsGrace,
    );
  }

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
    if (current == null || destination == null || segmentStops.length < 2) {
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

    final buffer = TransitWakeTuning.approachBufferMeters(
      vehicleType,
      wakeStopCount: wakeStop.stopSequence == destinationStop.stopSequence
          ? 0
          : 1,
    );
    return alongRouteRemainingMeters <= wakeToDestinationMeters + buffer;
  }

  /// Rebuilds [plan] so wake→destination meters match stop-chord geometry.
  ///
  /// Android FGS evaluates remaining distance on stop chords (no GTFS shapes).
  /// Foreground plans often store shape-based distances; mixing the two fires
  /// early on curved rail. Call this before isolate wake evaluation.
  static TransitWakePlan withStopChordWakeDistance(TransitWakePlan plan) {
    final wakeStop = plan.wakeStop;
    final destinationStop = plan.destinationStop;
    if (wakeStop == null || destinationStop == null) {
      return plan;
    }
    if (plan.wakeStopCount == 0 ||
        wakeStop.stopSequence == destinationStop.stopSequence) {
      if (plan.wakeToDestinationMeters == 0) {
        return plan;
      }
      return TransitWakePlan(
        routeId: plan.routeId,
        patternKey: plan.patternKey,
        wakeStopCount: plan.wakeStopCount,
        destinationStopSequence: plan.destinationStopSequence,
        wakeStopSequence: plan.wakeStopSequence,
        wakeToDestinationMeters: 0,
        segmentStops: plan.segmentStops,
        travelingForward: plan.travelingForward,
        vehicleType: plan.vehicleType,
      );
    }

    final chordMeters = alongRouteMetersBetweenStops(
      segmentStops: plan.segmentStops,
      fromStop: wakeStop,
      toStop: destinationStop,
      destinationStop: destinationStop,
    );
    if (chordMeters == null ||
        (chordMeters - plan.wakeToDestinationMeters).abs() < 1) {
      return plan;
    }

    return TransitWakePlan(
      routeId: plan.routeId,
      patternKey: plan.patternKey,
      wakeStopCount: plan.wakeStopCount,
      destinationStopSequence: plan.destinationStopSequence,
      wakeStopSequence: plan.wakeStopSequence,
      wakeToDestinationMeters: chordMeters,
      segmentStops: plan.segmentStops,
      travelingForward: plan.travelingForward,
      vehicleType: plan.vehicleType,
    );
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
