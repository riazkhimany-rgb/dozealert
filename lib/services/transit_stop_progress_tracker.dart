import 'package:geolocator/geolocator.dart';

import '../models/transit_stop.dart';

/// Keeps [currentStop] converging on the rider without jumping more than one
/// stop per GPS update.
///
/// Prevents noisy GPS or bad GTFS snaps from inflating (or deflating) route
/// progress and triggering stop-based wake alarms too early — while always
/// making progress toward the observed position so the count can never freeze.
class TransitStopProgressTracker {
  String? _routeId;
  int? _destinationStopSequence;
  int? _acceptedStopSequence;

  bool get hasEstablishedProgress =>
      _routeId != null && _acceptedStopSequence != null;

  void reset() {
    _routeId = null;
    _destinationStopSequence = null;
    _acceptedStopSequence = null;
  }

  void seedAcceptedSequence({
    required String routeId,
    required int destinationStopSequence,
    required int acceptedStopSequence,
    // Retained for API compatibility with callers; stop reconciliation is now
    // direction-agnostic (it always steps toward the observed raw match).
    required bool travelingForward,
  }) {
    _routeId = routeId;
    _destinationStopSequence = destinationStopSequence;
    _acceptedStopSequence = acceptedStopSequence;
  }

  /// Returns the stabilized stop to use instead of [rawStop].
  ///
  /// When [latitude]/[longitude] and [maxAdvanceDistanceMeters] are set,
  /// refuses to advance to a stop farther than that crow-flies distance — so
  /// rail cannot Bronte→Oakville in one fix while GPS is still near Bronte.
  TransitStop reconcile({
    required String routeId,
    required TransitStop destinationStop,
    required TransitStop rawStop,
    required List<TransitStop> routeStops,
    int maxStepsPerFix = 1,
    double? latitude,
    double? longitude,
    double? maxAdvanceDistanceMeters,
  }) {
    if (_routeId != routeId ||
        _destinationStopSequence != destinationStop.stopSequence) {
      _routeId = routeId;
      _destinationStopSequence = destinationStop.stopSequence;
      _acceptedStopSequence = rawStop.stopSequence;
      return rawStop;
    }

    final accepted = _stopForSequence(routeStops, _acceptedStopSequence!);
    if (accepted == null) {
      _acceptedStopSequence = rawStop.stopSequence;
      return rawStop;
    }

    if (rawStop.stopSequence == _acceptedStopSequence) {
      return accepted;
    }

    final steps = maxStepsPerFix.clamp(1, 2);
    var latest = accepted;
    for (var step = 0; step < steps; step++) {
      if (latest.stopSequence == rawStop.stopSequence) {
        break;
      }

      final candidate = _peekStepTowardRaw(
        fromSequence: latest.stopSequence,
        rawStop: rawStop,
        routeStops: routeStops,
      );
      if (candidate == null) {
        break;
      }

      if (!_mayAdvanceTo(
        candidate,
        latitude: latitude,
        longitude: longitude,
        maxAdvanceDistanceMeters: maxAdvanceDistanceMeters,
      )) {
        break;
      }

      latest = _stepTowardRaw(rawStop, routeStops);
    }
    return latest;
  }

  bool _mayAdvanceTo(
    TransitStop candidate, {
    required double? latitude,
    required double? longitude,
    required double? maxAdvanceDistanceMeters,
  }) {
    final cap = maxAdvanceDistanceMeters;
    if (cap == null || latitude == null || longitude == null) {
      return true;
    }
    final meters = Geolocator.distanceBetween(
      latitude,
      longitude,
      candidate.latitude,
      candidate.longitude,
    );
    return meters <= cap;
  }

  TransitStop? _peekStepTowardRaw({
    required int fromSequence,
    required TransitStop rawStop,
    required List<TransitStop> routeStops,
  }) {
    final rawSeq = rawStop.stopSequence;
    final forward = rawSeq > fromSequence;
    final adjacent = _adjacentStop(
      routeStops,
      fromSequence,
      forward: forward,
    );
    final overshoots = adjacent == null ||
        (forward
            ? adjacent.stopSequence >= rawSeq
            : adjacent.stopSequence <= rawSeq);
    return overshoots ? rawStop : adjacent;
  }

  /// Advances/retreats [_acceptedStopSequence] by a single stop toward
  /// [rawStop]. When the adjacent stop would overshoot the raw match, snaps
  /// directly to the raw stop instead.
  TransitStop _stepTowardRaw(
    TransitStop rawStop,
    List<TransitStop> routeStops,
  ) {
    final rawSeq = rawStop.stopSequence;
    final forward = rawSeq > _acceptedStopSequence!;
    final adjacent = _adjacentStop(
      routeStops,
      _acceptedStopSequence!,
      forward: forward,
    );

    final overshoots = adjacent == null ||
        (forward
            ? adjacent.stopSequence >= rawSeq
            : adjacent.stopSequence <= rawSeq);
    if (overshoots) {
      _acceptedStopSequence = rawSeq;
      return rawStop;
    }

    _acceptedStopSequence = adjacent.stopSequence;
    return adjacent;
  }

  /// The stop immediately after (forward) or before (backward) [fromSequence].
  ///
  /// Works with non-consecutive GTFS sequences by picking the nearest sequence
  /// strictly greater-than / less-than [fromSequence].
  TransitStop? _adjacentStop(
    List<TransitStop> routeStops,
    int fromSequence, {
    required bool forward,
  }) {
    TransitStop? best;
    for (final stop in routeStops) {
      final seq = stop.stopSequence;
      if (forward) {
        if (seq > fromSequence && (best == null || seq < best.stopSequence)) {
          best = stop;
        }
      } else {
        if (seq < fromSequence && (best == null || seq > best.stopSequence)) {
          best = stop;
        }
      }
    }
    return best;
  }

  TransitStop? _stopForSequence(List<TransitStop> routeStops, int sequence) {
    for (final stop in routeStops) {
      if (stop.stopSequence == sequence) {
        return stop;
      }
    }
    return null;
  }
}
