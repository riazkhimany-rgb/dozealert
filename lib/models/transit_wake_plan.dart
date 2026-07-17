import 'transit_stop.dart';
import 'transit_vehicle_type.dart';

/// Trip-scoped alarm target built from the locked route pattern.
///
/// Unlike the Home progress segment, [segmentStops] never shrinks as stops are
/// passed. This keeps the configured wake stop available for confirmation and
/// recovery even after the UI has advanced to the destination.
class TransitWakePlan {
  const TransitWakePlan({
    required this.routeId,
    required this.patternKey,
    required this.wakeStopCount,
    required this.destinationStopSequence,
    required this.wakeStopSequence,
    required this.wakeToDestinationMeters,
    required this.segmentStops,
    required this.travelingForward,
    this.vehicleType,
  });

  final String routeId;
  final String? patternKey;
  final int wakeStopCount;
  final int destinationStopSequence;
  final int wakeStopSequence;
  final double wakeToDestinationMeters;
  final List<TransitStop> segmentStops;
  final bool travelingForward;
  final TransitVehicleType? vehicleType;

  TransitStop? get wakeStop => _stopForSequence(wakeStopSequence);

  TransitStop? get destinationStop => _stopForSequence(destinationStopSequence);

  bool get isValid =>
      routeId.isNotEmpty &&
      segmentStops.isNotEmpty &&
      wakeStop != null &&
      destinationStop != null &&
      wakeToDestinationMeters >= 0;

  bool matchesTrip({
    required String routeId,
    required int destinationStopSequence,
    required String? patternKey,
  }) {
    return this.routeId == routeId &&
        this.destinationStopSequence == destinationStopSequence &&
        this.patternKey == patternKey;
  }

  /// True once stop tracking has reached or advanced beyond the fixed target.
  bool hasReachedWakeStop(int currentStopSequence) {
    return travelingForward
        ? currentStopSequence >= wakeStopSequence
        : currentStopSequence <= wakeStopSequence;
  }

  TransitStop? _stopForSequence(int sequence) {
    for (final stop in segmentStops) {
      if (stop.stopSequence == sequence) {
        return stop;
      }
    }
    return null;
  }

  static TransitStop? selectWakeStop({
    required List<TransitStop> segmentStops,
    required int wakeStopCount,
  }) {
    if (segmentStops.isEmpty) {
      return null;
    }
    final index = (segmentStops.length - 1 - wakeStopCount).clamp(
      0,
      segmentStops.length - 1,
    );
    return segmentStops[index];
  }
}
