class CurrentLocation {
  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
    this.heading = -1,
  });

  final double latitude;
  final double longitude;

  /// Speed in meters per second.
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  /// Compass heading in degrees (0–360), or -1 when unavailable.
  final double heading;

  double get speedKmh => speed * 3.6;

  bool get hasHeading => heading >= 0 && heading <= 360;

  CurrentLocation copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    double? accuracy,
    DateTime? timestamp,
    double? heading,
  }) {
    return CurrentLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      heading: heading ?? this.heading,
    );
  }
}
