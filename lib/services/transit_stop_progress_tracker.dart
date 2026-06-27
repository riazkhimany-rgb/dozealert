import '../models/transit_stop.dart';

/// Keeps [currentStop] from jumping forward more than one stop per GPS update.
///
/// Prevents noisy GPS or bad GTFS snaps from inflating route progress and
/// triggering stop-based wake alarms too early.
class TransitStopProgressTracker {
  String? _routeId;
  int? _destinationStopSequence;
  int? _acceptedStopSequence;
  bool? _travelingForward;

  void reset() {
    _routeId = null;
    _destinationStopSequence = null;
    _acceptedStopSequence = null;
    _travelingForward = null;
  }

  /// Returns the stabilized stop to use instead of [rawStop].
  TransitStop reconcile({
    required String routeId,
    required TransitStop destinationStop,
    required TransitStop rawStop,
    required List<TransitStop> routeStops,
  }) {
    final travelingForward = destinationStop.stopSequence >= rawStop.stopSequence;

    if (_routeId != routeId ||
        _destinationStopSequence != destinationStop.stopSequence) {
      _routeId = routeId;
      _destinationStopSequence = destinationStop.stopSequence;
      _travelingForward = travelingForward;
      _acceptedStopSequence = rawStop.stopSequence;
      return rawStop;
    }

    final accepted = _stopForSequence(routeStops, _acceptedStopSequence!);
    if (accepted == null) {
      _acceptedStopSequence = rawStop.stopSequence;
      _travelingForward = travelingForward;
      return rawStop;
    }

    if (rawStop.stopSequence == _acceptedStopSequence) {
      return accepted;
    }

    if (_travelingForward == true) {
      return _reconcileForward(rawStop, accepted, routeStops);
    }

    return _reconcileBackward(rawStop, accepted, routeStops);
  }

  TransitStop _reconcileForward(
    TransitStop rawStop,
    TransitStop accepted,
    List<TransitStop> routeStops,
  ) {
    final rawSeq = rawStop.stopSequence;
    final acceptedSeq = _acceptedStopSequence!;

    if (rawSeq > acceptedSeq) {
      if (rawSeq == acceptedSeq + 1) {
        _acceptedStopSequence = rawSeq;
        return rawStop;
      }
      return accepted;
    }

    if (rawSeq < acceptedSeq && acceptedSeq - rawSeq == 1) {
      _acceptedStopSequence = rawSeq;
      return rawStop;
    }

    return accepted;
  }

  TransitStop _reconcileBackward(
    TransitStop rawStop,
    TransitStop accepted,
    List<TransitStop> routeStops,
  ) {
    final rawSeq = rawStop.stopSequence;
    final acceptedSeq = _acceptedStopSequence!;

    if (rawSeq < acceptedSeq) {
      if (rawSeq == acceptedSeq - 1) {
        _acceptedStopSequence = rawSeq;
        return rawStop;
      }
      return accepted;
    }

    if (rawSeq > acceptedSeq && rawSeq - acceptedSeq == 1) {
      _acceptedStopSequence = rawSeq;
      return rawStop;
    }

    return accepted;
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
