import '../models/trip_pattern_concern.dart';
import '../models/transit_stop.dart';
import '../services/gtfs_service.dart';

class TripPatternValidation {
  const TripPatternValidation({
    this.concern,
    this.directionLabel,
  });

  final String? concern;
  final String? directionLabel;

  bool get hasConcern => concern != null;
}

TripPatternValidation validateTripOnPattern({
  required List<TransitStop> pattern,
  required TransitStop current,
  required TransitStop destination,
  required String? patternKey,
  required bool directionLocked,
}) {
  final directionLabel = GtfsService.directionLabelForPatternKey(patternKey);

  if (pattern.isEmpty) {
    return TripPatternValidation(directionLabel: directionLabel);
  }

  final forward = destination.stopSequence >= current.stopSequence;
  final remaining = (destination.stopSequence - current.stopSequence).abs();
  final patternLength = pattern.length;

  if (directionLocked && !forward && remaining > 0) {
    return TripPatternValidation(
      concern: TripPatternConcern.wrongDirection,
      directionLabel: directionLabel,
    );
  }

  if (directionLocked &&
      remaining > 8 &&
      remaining > (patternLength * 0.55).ceil()) {
    return TripPatternValidation(
      concern: TripPatternConcern.unlikelyRoute,
      directionLabel: directionLabel,
    );
  }

  return TripPatternValidation(directionLabel: directionLabel);
}
