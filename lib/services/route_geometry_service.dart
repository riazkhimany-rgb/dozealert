import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/transit_stop.dart';

/// A polyline built from ordered route stops (GTFS shapes fallback).
class RoutePolyline {
  const RoutePolyline({
    required this.stops,
    required this.segments,
    required this.totalLengthMeters,
    required this.travelingForward,
  });

  final List<TransitStop> stops;
  final List<RouteSegment> segments;
  final double totalLengthMeters;
  final bool travelingForward;
}

class RouteSegment {
  const RouteSegment({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    required this.startAlongMeters,
    required this.lengthMeters,
    required this.fromStopSequence,
    required this.toStopSequence,
  });

  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;
  final double startAlongMeters;
  final double lengthMeters;
  final int fromStopSequence;
  final int toStopSequence;

  double get endAlongMeters => startAlongMeters + lengthMeters;
}

/// Result of projecting a GPS fix onto the route polyline.
class RouteProjection {
  const RouteProjection({
    required this.latitude,
    required this.longitude,
    required this.alongRouteMeters,
    required this.offRouteMeters,
    required this.segmentIndex,
  });

  final double latitude;
  final double longitude;
  final double alongRouteMeters;
  final double offRouteMeters;
  final int segmentIndex;
}

/// Along-route geometry from GTFS stop chains (bus + rail).
class RouteGeometryService {
  RoutePolyline buildPolyline({
    required List<TransitStop> routeStops,
    required TransitStop destinationStop,
  }) {
    final stops = List<TransitStop>.from(routeStops)
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

    final travelingForward =
        destinationStop.stopSequence >= stops.first.stopSequence;

    final segments = <RouteSegment>[];
    var along = 0.0;

    for (var index = 0; index < stops.length - 1; index++) {
      final from = stops[index];
      final to = stops[index + 1];
      final length = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

      if (length <= 0) {
        continue;
      }

      segments.add(
        RouteSegment(
          startLat: from.latitude,
          startLon: from.longitude,
          endLat: to.latitude,
          endLon: to.longitude,
          startAlongMeters: along,
          lengthMeters: length,
          fromStopSequence: from.stopSequence,
          toStopSequence: to.stopSequence,
        ),
      );
      along += length;
    }

    return RoutePolyline(
      stops: stops,
      segments: segments,
      totalLengthMeters: along,
      travelingForward: travelingForward,
    );
  }

  RouteProjection? projectOnPolyline({
    required RoutePolyline polyline,
    required double latitude,
    required double longitude,
  }) {
    if (polyline.segments.isEmpty) {
      return null;
    }

    RouteProjection? best;
    var bestOffRoute = double.infinity;

    for (var index = 0; index < polyline.segments.length; index++) {
      final segment = polyline.segments[index];
      final projection = _projectOnSegment(
        segment: segment,
        latitude: latitude,
        longitude: longitude,
        segmentIndex: index,
      );

      if (projection.offRouteMeters < bestOffRoute) {
        bestOffRoute = projection.offRouteMeters;
        best = projection;
      }
    }

    return best;
  }

  double? alongRouteRemainingMeters({
    required RoutePolyline polyline,
    required RouteProjection projection,
    required TransitStop destinationStop,
  }) {
    final destinationAlong = _alongMetersForStop(
      polyline: polyline,
      stop: destinationStop,
    );
    if (destinationAlong == null) {
      return null;
    }

    final remaining = (destinationAlong - projection.alongRouteMeters).abs();
    return math.max(0, remaining);
  }

  double? _alongMetersForStop({
    required RoutePolyline polyline,
    required TransitStop stop,
  }) {
    for (final segment in polyline.segments) {
      if (segment.fromStopSequence == stop.stopSequence) {
        return segment.startAlongMeters;
      }
      if (segment.toStopSequence == stop.stopSequence) {
        return segment.endAlongMeters;
      }
    }

    if (polyline.stops.isEmpty) {
      return null;
    }

    final first = polyline.stops.first;
    final last = polyline.stops.last;
    if (stop.stopSequence == first.stopSequence) {
      return 0;
    }
    if (stop.stopSequence == last.stopSequence) {
      return polyline.totalLengthMeters;
    }

    return null;
  }

  TransitStop? matchCurrentStop({
    required RoutePolyline polyline,
    required RouteProjection projection,
    required TransitStop destinationStop,
    required int maxOffRouteMeters,
    double? headingDegrees,
    double? speedMps,
  }) {
    if (projection.offRouteMeters > maxOffRouteMeters) {
      return null;
    }

    final candidates = polyline.stops.where((stop) {
      final along = _alongMetersForStop(polyline: polyline, stop: stop);
      if (along == null) {
        return false;
      }

      if (polyline.travelingForward) {
        return along <= projection.alongRouteMeters + 250;
      }
      return along >= projection.alongRouteMeters - 250;
    }).toList();

    if (candidates.isEmpty) {
      return _nearestStop(
        latitude: projection.latitude,
        longitude: projection.longitude,
        stops: polyline.stops,
        maxDistanceMeters: maxOffRouteMeters.toDouble(),
      );
    }

    if (_shouldUseHeading(headingDegrees, speedMps)) {
      final headingFiltered = candidates.where((stop) {
        final bearing = Geolocator.bearingBetween(
          projection.latitude,
          projection.longitude,
          stop.latitude,
          stop.longitude,
        );
        return _headingDelta(bearing, headingDegrees!) <= 70;
      }).toList();

      if (headingFiltered.isNotEmpty) {
        candidates
          ..clear()
          ..addAll(headingFiltered);
      }
    }

    TransitStop? best;
    var bestScore = double.infinity;

    for (final stop in candidates) {
      final along = _alongMetersForStop(polyline: polyline, stop: stop)!;
      final alongDelta = (projection.alongRouteMeters - along).abs();
      final directDistance = Geolocator.distanceBetween(
        projection.latitude,
        projection.longitude,
        stop.latitude,
        stop.longitude,
      );
      final score = alongDelta + directDistance * 0.35;

      if (score < bestScore) {
        bestScore = score;
        best = stop;
      }
    }

    return best;
  }

  TransitStop? _nearestStop({
    required double latitude,
    required double longitude,
    required List<TransitStop> stops,
    required double maxDistanceMeters,
  }) {
    TransitStop? nearest;
    var nearestDistance = double.infinity;

    for (final stop in stops) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        stop.latitude,
        stop.longitude,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = stop;
      }
    }

    if (nearest == null || nearestDistance > maxDistanceMeters) {
      return null;
    }

    return nearest;
  }

  bool _shouldUseHeading(double? headingDegrees, double? speedMps) {
    if (headingDegrees == null || headingDegrees < 0) {
      return false;
    }
    final speed = speedMps ?? 0;
    return speed >= 2.5;
  }

  double _headingDelta(double bearing, double heading) {
    var delta = (bearing - heading).abs() % 360;
    if (delta > 180) {
      delta = 360 - delta;
    }
    return delta;
  }

  RouteProjection _projectOnSegment({
    required RouteSegment segment,
    required double latitude,
    required double longitude,
    required int segmentIndex,
  }) {
    if (segment.lengthMeters <= 0) {
      return RouteProjection(
        latitude: segment.startLat,
        longitude: segment.startLon,
        alongRouteMeters: segment.startAlongMeters,
        offRouteMeters: Geolocator.distanceBetween(
          latitude,
          longitude,
          segment.startLat,
          segment.startLon,
        ),
        segmentIndex: segmentIndex,
      );
    }

    final startToPoint = Geolocator.distanceBetween(
      segment.startLat,
      segment.startLon,
      latitude,
      longitude,
    );
    final startToEndBearing = Geolocator.bearingBetween(
      segment.startLat,
      segment.startLon,
      segment.endLat,
      segment.endLon,
    );
    final startToPointBearing = Geolocator.bearingBetween(
      segment.startLat,
      segment.startLon,
      latitude,
      longitude,
    );
    final angleDiff = _headingDelta(startToPointBearing, startToEndBearing);
    final alongMeters =
        startToPoint * math.cos(angleDiff * math.pi / 180.0);
    final t = _clamp01(alongMeters / segment.lengthMeters);

    final projectedLat =
        segment.startLat + (segment.endLat - segment.startLat) * t;
    final projectedLon =
        segment.startLon + (segment.endLon - segment.startLon) * t;
    final along = segment.startAlongMeters + segment.lengthMeters * t;
    final offRoute = Geolocator.distanceBetween(
      latitude,
      longitude,
      projectedLat,
      projectedLon,
    );

    return RouteProjection(
      latitude: projectedLat,
      longitude: projectedLon,
      alongRouteMeters: along,
      offRouteMeters: offRoute,
      segmentIndex: segmentIndex,
    );
  }

  double _clamp01(double value) {
    if (value.isNaN) {
      return 0;
    }
    return value.clamp(0.0, 1.0);
  }
}
