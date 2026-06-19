class TransitStop {
  const TransitStop({
    required this.stopId,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    required this.routeId,
    required this.stopSequence,
  });

  final String stopId;
  final String stopName;
  final double latitude;
  final double longitude;
  final String routeId;
  final int stopSequence;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitStop &&
            other.stopId == stopId &&
            other.stopName == stopName &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            other.routeId == routeId &&
            other.stopSequence == stopSequence;
  }

  @override
  int get hashCode => Object.hash(
        stopId,
        stopName,
        latitude,
        longitude,
        routeId,
        stopSequence,
      );
}
