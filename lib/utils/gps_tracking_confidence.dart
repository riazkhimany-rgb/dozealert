import '../services/transit_mode_service.dart';

/// Heuristic confidence used to relax conservative stop-progress caps.
class GpsTrackingConfidence {
  const GpsTrackingConfidence._();

  static const highAccuracyMeters = 25.0;
  static const minVehicleSpeedMps = 2.0;

  static bool isHigh({
    required bool directionLocked,
    required double? offRouteMeters,
    required double accuracyMeters,
    required double? speedMps,
    required bool inVehicle,
  }) {
    if (!directionLocked || !inVehicle) {
      return false;
    }

    if (accuracyMeters <= 0 || accuracyMeters > highAccuracyMeters) {
      return false;
    }

    final offRoute = offRouteMeters;
    if (offRoute == null || offRoute > TransitModeService.routeStopMatchMeters) {
      return false;
    }

    final speed = speedMps;
    if (speed == null || speed < minVehicleSpeedMps) {
      return false;
    }

    return true;
  }
}
