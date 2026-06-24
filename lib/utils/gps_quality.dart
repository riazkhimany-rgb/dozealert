import '../models/current_location.dart';

/// Filters noisy GPS fixes and lightly smooths accepted positions.
class GpsQualityGate {
  const GpsQualityGate({
    this.maxAccuracyMeters = 80,
    this.degradedAccuracyMeters = 150,
  });

  final double maxAccuracyMeters;
  final double degradedAccuracyMeters;

  bool accept(CurrentLocation location, {bool allowDegraded = false}) {
    if (location.accuracy <= 0) {
      return true;
    }

    if (location.accuracy <= maxAccuracyMeters) {
      return true;
    }

    return allowDegraded && location.accuracy <= degradedAccuracyMeters;
  }
}

class GpsPositionSmoother {
  CurrentLocation? _previous;

  CurrentLocation smooth(CurrentLocation location) {
    final previous = _previous;
    if (previous == null) {
      _previous = location;
      return location;
    }

    final accuracyWeight = (1 / (1 + location.accuracy / 25)).clamp(0.15, 0.85);
    final alpha = (0.35 + accuracyWeight * 0.35).clamp(0.35, 0.75);

    final smoothed = CurrentLocation(
      latitude: _lerp(previous.latitude, location.latitude, alpha),
      longitude: _lerp(previous.longitude, location.longitude, alpha),
      speed: location.speed >= 0 ? location.speed : previous.speed,
      accuracy: mathMin(previous.accuracy, location.accuracy),
      timestamp: location.timestamp,
      heading: location.heading >= 0 ? location.heading : previous.heading,
    );

    _previous = smoothed;
    return smoothed;
  }

  void reset() {
    _previous = null;
  }

  double _lerp(double from, double to, double t) => from + (to - from) * t;

  double mathMin(double a, double b) => a < b ? a : b;
}
