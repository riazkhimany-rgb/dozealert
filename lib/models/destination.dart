class Destination {
  const Destination({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.stationKey,
  });

  final String name;
  final double latitude;
  final double longitude;

  /// Stable station identity for pattern-local stop resolution.
  final String? stationKey;

  Destination copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? stationKey,
  }) {
    return Destination(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      stationKey: stationKey ?? this.stationKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Destination &&
            other.name == name &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            other.stationKey == stationKey;
  }

  @override
  int get hashCode => Object.hash(name, latitude, longitude, stationKey);
}
