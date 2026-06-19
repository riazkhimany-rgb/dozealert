class TransitStation {
  const TransitStation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.stationOrder,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int stationOrder;

  factory TransitStation.fromJson(Map<String, dynamic> json) {
    return TransitStation(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      stationOrder: json['stationOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'stationOrder': stationOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitStation &&
            other.name == name &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            other.stationOrder == stationOrder;
  }

  @override
  int get hashCode => Object.hash(name, latitude, longitude, stationOrder);
}
