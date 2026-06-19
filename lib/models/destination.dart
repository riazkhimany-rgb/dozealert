class Destination {
  const Destination({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  Destination copyWith({
    String? name,
    double? latitude,
    double? longitude,
  }) {
    return Destination(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Destination &&
            other.name == name &&
            other.latitude == latitude &&
            other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(name, latitude, longitude);
}
