import '../models/transit_vehicle_type.dart';

/// Vehicle-specific wake timing knobs. Bus and train are tuned independently
/// so tightening one mode does not affect the other.
class TransitWakeTuning {
  const TransitWakeTuning._();

  /// How far along-route past the wake stop GPS may still count as "near".
  static double approachBufferMeters(TransitVehicleType? vehicleType) {
    return switch (vehicleType) {
      TransitVehicleType.train => 350,
      TransitVehicleType.lightRail => 250,
      TransitVehicleType.subway => 200,
      TransitVehicleType.streetcar => 100,
      TransitVehicleType.bus => 120,
      null => 120,
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
}
