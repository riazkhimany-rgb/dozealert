/// Ordered lat/lon points from GTFS shapes.txt for a route pattern.
class RouteShapePolyline {
  const RouteShapePolyline({
    required this.routeId,
    required this.patternKey,
    required this.points,
  });

  final String routeId;
  final String patternKey;
  final List<RouteShapePoint> points;

  String get storageKey => '$routeId|$patternKey';
}

class RouteShapePoint {
  const RouteShapePoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
