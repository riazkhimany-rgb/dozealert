import 'gps_tracking_confidence.dart';
import '../services/transit_mode_service.dart';

/// Motion-aware rules for stop progress and approach wake.
class RiderMotionRules {
  const RiderMotionRules._();

  static const onFootSpeedMps = 1.5;

  /// True when speed or activity indicates the rider is on a moving vehicle.
  ///
  /// GPS speed wins over activity when they disagree — e.g. a train classified
  /// as [ActivityType.still] while moving.
  static bool resolvesInVehicle({
    required bool useActivityRecognition,
    bool? activityInVehicle,
    double? speedMps,
  }) {
    if (!useActivityRecognition) {
      return speedMps != null &&
          speedMps >= GpsTrackingConfidence.minVehicleSpeedMps;
    }

    if (speedMps != null &&
        speedMps >= GpsTrackingConfidence.minVehicleSpeedMps) {
      return true;
    }

    if (activityInVehicle == true) {
      return true;
    }

    return false;
  }

  /// True when low speed or activity indicates waiting/walking at a platform.
  static bool resolvesOnFoot({
    required bool useActivityRecognition,
    bool? activityInVehicle,
    bool? activityOnFoot,
    double? speedMps,
  }) {
    if (!useActivityRecognition) {
      return false;
    }

    if (speedMps != null &&
        speedMps >= GpsTrackingConfidence.minVehicleSpeedMps) {
      return false;
    }

    if (activityInVehicle == true) {
      return false;
    }

    if (activityOnFoot == true) {
      return true;
    }

    return speedMps != null && speedMps < onFootSpeedMps;
  }

  static bool allowsRelaxedStopProgress({
    required bool useActivityRecognition,
    required bool? activityInVehicle,
    required bool? activityOnFoot,
    required bool directionLocked,
    required double? offRouteMeters,
    required double accuracyMeters,
    required double? speedMps,
  }) {
    if (!useActivityRecognition) {
      if (!directionLocked) {
        return false;
      }
      final offRoute = offRouteMeters;
      if (offRoute != null && offRoute > TransitModeService.routeStopMatchMeters) {
        return false;
      }
      return accuracyMeters <= 0 ||
          accuracyMeters <= GpsTrackingConfidence.highAccuracyMeters * 4;
    }

    if (resolvesOnFoot(
      useActivityRecognition: useActivityRecognition,
      activityInVehicle: activityInVehicle,
      activityOnFoot: activityOnFoot,
      speedMps: speedMps,
    )) {
      return false;
    }

    return GpsTrackingConfidence.isHigh(
      directionLocked: directionLocked,
      offRouteMeters: offRouteMeters,
      accuracyMeters: accuracyMeters,
      speedMps: speedMps,
      inVehicle: resolvesInVehicle(
        useActivityRecognition: useActivityRecognition,
        activityInVehicle: activityInVehicle,
        speedMps: speedMps,
      ),
    );
  }

  static bool allowsApproachWake({
    required bool useActivityRecognition,
    required bool? activityInVehicle,
    required bool? activityOnFoot,
    required double? speedMps,
  }) {
    if (!useActivityRecognition) {
      return true;
    }

    if (resolvesOnFoot(
      useActivityRecognition: useActivityRecognition,
      activityInVehicle: activityInVehicle,
      activityOnFoot: activityOnFoot,
      speedMps: speedMps,
    )) {
      return false;
    }

    return resolvesInVehicle(
      useActivityRecognition: useActivityRecognition,
      activityInVehicle: activityInVehicle,
      speedMps: speedMps,
    );
  }
}
