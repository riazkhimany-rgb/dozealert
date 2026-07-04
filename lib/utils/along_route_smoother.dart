import 'dart:math' as math;

/// 1D Kalman filter for along-route remaining distance on a fixed corridor.
class AlongRouteKalmanFilter {
  AlongRouteKalmanFilter({
    this.initialVariance = 2500,
    this.maxPredictSeconds = 120,
  }) : _variance = initialVariance;

  final double initialVariance;
  final double maxPredictSeconds;

  double? _estimateMeters;
  late double _variance;
  DateTime? _lastTimestamp;

  double filter({
    required double measuredRemainingMeters,
    required double accuracyMeters,
    required DateTime timestamp,
    double? speedMps,
  }) {
    final previousTime = _lastTimestamp;

    if (_estimateMeters == null) {
      _estimateMeters = measuredRemainingMeters;
      _variance = math.max(
        accuracyMeters * accuracyMeters,
        initialVariance,
      );
      _lastTimestamp = timestamp;
      return _estimateMeters!;
    }

    if (previousTime != null && timestamp.isBefore(previousTime)) {
      return _estimateMeters!;
    }

    if (previousTime != null) {
      final elapsedSeconds =
          timestamp.difference(previousTime).inMilliseconds / 1000.0;
      if (elapsedSeconds > 0 && elapsedSeconds <= maxPredictSeconds) {
        final speed = speedMps;
        if (speed != null && speed > 0) {
          _estimateMeters =
              math.max(0, _estimateMeters! - speed * elapsedSeconds);
        }
        _variance += elapsedSeconds * 4;
      }
    }

    final measurementVariance = math.max(
      accuracyMeters * accuracyMeters,
      25,
    ).clamp(25, 10_000);
    final gain = _variance / (_variance + measurementVariance);
    _estimateMeters =
        _estimateMeters! + gain * (measuredRemainingMeters - _estimateMeters!);
    _variance = (1 - gain) * _variance;
    _lastTimestamp = timestamp;
    return _estimateMeters!;
  }

  /// Alias kept for call sites that previously used [AlongRouteSmoother.smooth].
  double smooth({
    required double alongRouteMeters,
    required double accuracyMeters,
    DateTime? timestamp,
    double? speedMps,
  }) {
    return filter(
      measuredRemainingMeters: alongRouteMeters,
      accuracyMeters: accuracyMeters,
      timestamp: timestamp ?? DateTime.now(),
      speedMps: speedMps,
    );
  }

  void reset() {
    _estimateMeters = null;
    _variance = initialVariance;
    _lastTimestamp = null;
  }
}

/// Backwards-compatible alias used by [TransitModeService].
typedef AlongRouteSmoother = AlongRouteKalmanFilter;
