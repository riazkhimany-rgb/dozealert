import '../models/transit_vehicle_type.dart';

/// Vehicle-specific wake timing knobs. Bus and train are tuned independently
/// so tightening one mode does not affect the other.
class TransitWakeTuning {
  const TransitWakeTuning._();

  /// How far along-route past the wake stop GPS may still count as "near".
  ///
  /// [wakeStopCount] of `0` (at destination) uses a tighter lead so rail does
  /// not confirm hundreds of metres before the platform.
  static double approachBufferMeters(
    TransitVehicleType? vehicleType, {
    int wakeStopCount = 0,
  }) {
    if (wakeStopCount == 0) {
      return switch (vehicleType) {
        TransitVehicleType.train => 100,
        TransitVehicleType.lightRail => 120,
        TransitVehicleType.subway => 120,
        TransitVehicleType.streetcar => 80,
        TransitVehicleType.bus => 100,
        null => 100,
      };
    }

    return switch (vehicleType) {
      TransitVehicleType.train => 150,
      TransitVehicleType.lightRail => 200,
      TransitVehicleType.subway => 200,
      TransitVehicleType.streetcar => 100,
      TransitVehicleType.bus => 120,
      null => 120,
    };
  }

  /// How long a stop-confirmed wake waits for usable route GPS before falling
  /// back to stable stop progress. Underground modes intentionally wait less.
  static Duration poorGpsGracePeriod(TransitVehicleType? vehicleType) {
    return switch (vehicleType) {
      TransitVehicleType.subway => const Duration(seconds: 20),
      TransitVehicleType.lightRail => const Duration(seconds: 30),
      TransitVehicleType.streetcar => const Duration(seconds: 30),
      TransitVehicleType.bus => const Duration(seconds: 30),
      TransitVehicleType.train => const Duration(seconds: 45),
      null => const Duration(seconds: 30),
    };
  }

  /// Max along-route lead when snapping GPS to a stop ahead on the polyline.
  static double stopSnapAlongToleranceMeters(TransitVehicleType? vehicleType) {
    return switch (vehicleType) {
      TransitVehicleType.train => 20,
      TransitVehicleType.lightRail => 25,
      TransitVehicleType.subway => 30,
      _ => 35,
    };
  }

  /// Stops the progress tracker may advance per GPS fix.
  static int maxStepsPerFix({
    required TransitVehicleType? vehicleType,
    required bool highConfidence,
  }) {
    if (vehicleType == TransitVehicleType.train) {
      return 1;
    }
    return highConfidence ? 1 : 1;
  }

  /// Max crow-flies distance from the rider to the wake stop before a
  /// distance-based wake may confirm. Along-route remaining alone can look
  /// "at Oakville" when GPS projects ahead on open rail ~1–1.5 km early.
  static double wakeStopConfirmProximityMeters(TransitVehicleType? vehicleType) {
    return switch (vehicleType) {
      TransitVehicleType.train => 400,
      TransitVehicleType.lightRail => 350,
      TransitVehicleType.subway => 300,
      TransitVehicleType.streetcar => 200,
      TransitVehicleType.bus => 250,
      null => 300,
    };
  }

  /// Rail (and subway) must see a few armed fixes before distance confirm so
  /// a single optimistic projection cannot fire immediately after arming.
  static bool requiresStableArmBeforeDistanceConfirm(
    TransitVehicleType? vehicleType,
  ) {
    return switch (vehicleType) {
      TransitVehicleType.train ||
      TransitVehicleType.lightRail ||
      TransitVehicleType.subway =>
        true,
      _ => false,
    };
  }

  /// Max crow-flies distance to the *next* stop when advancing progress.
  /// Blocks Bronte→Oakville single-step snaps while GPS is still near Bronte.
  static double? maxStopAdvanceHaversineMeters(TransitVehicleType? vehicleType) {
    return switch (vehicleType) {
      TransitVehicleType.train => 800,
      TransitVehicleType.lightRail => 600,
      TransitVehicleType.subway => 500,
      _ => null,
    };
  }

  /// Rail/subway modes where polyline projection often lags the platform.
  static bool usesPlatformCatchUp(TransitVehicleType? vehicleType) {
    return switch (vehicleType) {
      TransitVehicleType.train ||
      TransitVehicleType.lightRail ||
      TransitVehicleType.subway =>
        true,
      _ => false,
    };
  }

  /// When along-route remaining is below this, allow geographic catch-up to
  /// stops ahead of the polyline projection (fixes "one station behind" UI).
  static double platformCatchUpAlongRemainingMeters(
    TransitVehicleType? vehicleType,
  ) {
    return switch (vehicleType) {
      TransitVehicleType.train => 650,
      TransitVehicleType.lightRail => 550,
      TransitVehicleType.subway => 500,
      _ => 400,
    };
  }

  /// Extra arm fixes required for poor-GPS fallback on rail when no fix is
  /// available to prove wake-stop proximity.
  static int minStableArmFixesForPoorGps(TransitVehicleType? vehicleType) {
    return switch (vehicleType) {
      TransitVehicleType.train => 4,
      TransitVehicleType.lightRail => 3,
      TransitVehicleType.subway => 3,
      _ => 2,
    };
  }
}
