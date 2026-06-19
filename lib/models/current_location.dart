class CurrentLocation {
  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;

  /// Speed in meters per second.
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  double get speedKmh => speed * 3.6;

  CurrentLocation copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return CurrentLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
