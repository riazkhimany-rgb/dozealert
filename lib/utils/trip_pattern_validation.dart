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

/// Distance (m) within which the rider is treated as effectively arriving, so
/// transient stop-sequence noise must never surface a direction concern.
const _nearDestinationMeters = 700.0;

/// Minimum stops the current match must sit *past* the destination before a
/// wrong-direction concern is trusted. A single stop of overshoot is almost
/// always GPS/matching noise rather than the rider genuinely reversing.
const _wrongDirectionStopMargin = 2;

TripPatternValidation validateTripOnPattern({
  required List<TransitStop> pattern,
  required TransitStop current,
  required TransitStop destination,
  required String? patternKey,
  required bool directionLocked,
  String? pendingPatternKey,
  double? alongRouteRemainingMeters,
}) {
  final labelKey = directionLocked
      ? patternKey
      : (pendingPatternKey ?? patternKey);
  final directionLabel = GtfsService.directionLabelForPatternKey(labelKey);

  if (pattern.isEmpty) {
    return TripPatternValidation(directionLabel: directionLabel);
  }

  // Never raise a concern when the rider is essentially at/approaching the
  // destination — the geometry is reliable there and the alarm must fire.
  final nearDestination = alongRouteRemainingMeters != null &&
      alongRouteRemainingMeters <= _nearDestinationMeters;
  if (nearDestination) {
    return TripPatternValidation(directionLabel: directionLabel);
  }

  final forward = destination.stopSequence >= current.stopSequence;
  final remaining = (destination.stopSequence - current.stopSequence).abs();

  if (directionLocked && !forward && remaining >= _wrongDirectionStopMargin) {
    return TripPatternValidation(
      concern: TripPatternConcern.wrongDirection,
      directionLabel: directionLabel,
    );
  }

  return TripPatternValidation(directionLabel: directionLabel);
}
