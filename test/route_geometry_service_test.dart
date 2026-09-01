import 'package:dozealert/models/current_location.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/models/route_shape_polyline.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/route_geometry_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';
import 'package:dozealert/utils/gps_quality.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/go_transit_test_feed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RouteGeometryService', () {
    final geometry = RouteGeometryService();

    test('projects a point onto a stop chain and computes remaining distance', () {
      final stops = [
        const TransitStop(
          stopId: '1',
          stopName: 'A',
          latitude: 43.6500,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 1,
        ),
        const TransitStop(
          stopId: '2',
          stopName: 'B',
          latitude: 43.6600,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 2,
        ),
        const TransitStop(
          stopId: '3',
          stopName: 'C',
          latitude: 43.6700,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 3,
        ),
      ];

      final destination = stops.last;
      final polyline = geometry.buildPolyline(
        routeStops: stops,
        destinationStop: destination,
      );
      final projection = geometry.projectOnPolyline(
        polyline: polyline,
        latitude: 43.6550,
        longitude: -79.3800,
      );

      expect(projection, isNotNull);
      expect(projection!.offRouteMeters, lessThan(500));

      final remaining = geometry.alongRouteRemainingMeters(
        polyline: polyline,
        projection: projection,
        destinationStop: destination,
      );

      expect(remaining, isNotNull);
      expect(remaining!, greaterThan(0));
      expect(remaining, lessThan(polyline.totalLengthMeters));
    });

    test('matchCurrentStop does not snap to stops ahead on the route', () {
      final stops = [
        const TransitStop(
          stopId: '1',
          stopName: 'A',
          latitude: 43.6500,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 1,
        ),
        const TransitStop(
          stopId: '2',
          stopName: 'B',
          latitude: 43.6600,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 2,
        ),
        const TransitStop(
          stopId: '3',
          stopName: 'C',
          latitude: 43.6700,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 3,
        ),
      ];

      final destination = stops.last;
      final polyline = geometry.buildPolyline(
        routeStops: stops,
        destinationStop: destination,
      );
      final projection = geometry.projectOnPolyline(
        polyline: polyline,
        latitude: 43.6550,
        longitude: -79.3800,
      );

      expect(projection, isNotNull);

      final matched = geometry.matchCurrentStop(
        polyline: polyline,
        projection: projection!,
        destinationStop: destination,
        maxOffRouteMeters: 1000,
      );

      expect(matched?.stopName, 'A');
    });

    test('remaining at destination is small even when shape hinterland is long', () {
      const origin = TransitStop(
        stopId: 'oakville',
        stopName: 'Oakville GO',
        latitude: 43.4550,
        longitude: -79.6820,
        routeId: 'lw',
        stopSequence: 1,
      );
      const destination = TransitStop(
        stopId: 'bronte',
        stopName: 'Bronte GO',
        latitude: 43.4165,
        longitude: -79.7220,
        routeId: 'lw',
        stopSequence: 2,
      );

      // Dense shape so many points nearer Bronte start ~2.3 km before the station.
      final shapePoints = <RouteShapePoint>[
        const RouteShapePoint(latitude: 43.4550, longitude: -79.6820),
        const RouteShapePoint(latitude: 43.4450, longitude: -79.6920),
        const RouteShapePoint(latitude: 43.4350, longitude: -79.7020),
        const RouteShapePoint(latitude: 43.4280, longitude: -79.7100),
        const RouteShapePoint(latitude: 43.4220, longitude: -79.7160),
        const RouteShapePoint(latitude: 43.4165, longitude: -79.7220),
      ];

      final polyline = geometry.buildPolyline(
        routeStops: [origin, destination],
        destinationStop: destination,
        shapePoints: shapePoints,
      );
      final atPlatform = geometry.projectOnPolyline(
        polyline: polyline,
        latitude: destination.latitude,
        longitude: destination.longitude,
      );

      expect(atPlatform, isNotNull);
      final remaining = geometry.alongRouteRemainingMeters(
        polyline: polyline,
        projection: atPlatform!,
        destinationStop: destination,
      );

      expect(remaining, isNotNull);
      expect(remaining!, lessThan(250));
    });

    test('empty candidate fallback stays at or behind projection', () {
      final stops = [
        const TransitStop(
          stopId: '1',
          stopName: 'A',
          latitude: 43.6500,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 1,
        ),
        const TransitStop(
          stopId: '2',
          stopName: 'B',
          latitude: 43.6600,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 2,
        ),
        const TransitStop(
          stopId: '3',
          stopName: 'C',
          latitude: 43.6700,
          longitude: -79.3800,
          routeId: 'test',
          stopSequence: 3,
        ),
      ];

      final destination = stops.last;
      final polyline = geometry.buildPolyline(
        routeStops: stops,
        destinationStop: destination,
      );
      final projection = geometry.projectOnPolyline(
        polyline: polyline,
        latitude: 43.6550,
        longitude: -79.3800,
      );

      expect(projection, isNotNull);

      final fallback = geometry.bestStopAtOrBehindProjection(
        polyline: polyline,
        projection: projection!,
      );

      expect(fallback?.stopName, 'A');
    });

    test('refineStopForPlatformApproach snaps to destination when near platform', () {
      const union = TransitStop(
        stopId: 'union',
        stopName: 'Union Station',
        latitude: 43.6453,
        longitude: -79.3806,
        routeId: 'lw',
        stopSequence: 1,
      );
      const exhibition = TransitStop(
        stopId: 'exhibition',
        stopName: 'Exhibition GO',
        latitude: 43.6359,
        longitude: -79.4186,
        routeId: 'lw',
        stopSequence: 2,
      );
      const stops = [union, exhibition];

      final refined = geometry.refineStopForPlatformApproach(
        currentStop: union,
        routeStops: stops,
        destinationStop: exhibition,
        alongRouteRemainingMeters: 100,
        latitude: exhibition.latitude,
        longitude: exhibition.longitude,
        vehicleType: TransitVehicleType.train,
      );

      expect(refined.stopName, 'Exhibition GO');
    });

    test('refineStopForPlatformApproach does not snap when still far on the line', () {
      const bronte = TransitStop(
        stopId: 'bronte',
        stopName: 'Bronte GO',
        latitude: 43.4165,
        longitude: -79.7220,
        routeId: 'lw',
        stopSequence: 1,
      );
      const oakville = TransitStop(
        stopId: 'oakville',
        stopName: 'Oakville GO',
        latitude: 43.4550,
        longitude: -79.6820,
        routeId: 'lw',
        stopSequence: 2,
      );
      const stops = [bronte, oakville];

      final refined = geometry.refineStopForPlatformApproach(
        currentStop: bronte,
        routeStops: stops,
        destinationStop: oakville,
        alongRouteRemainingMeters: 5000,
        latitude: bronte.latitude,
        longitude: bronte.longitude,
        vehicleType: TransitVehicleType.train,
      );

      expect(refined.stopName, 'Bronte GO');
    });
  });

  group('TransitModeService geometry integration', () {
    late GtfsService gtfsService;
    late TransitModeService transitModeService;

    setUp(() async {
      gtfsService = GtfsService();
      await gtfsService.initializeFromFallbackData();
      gtfsService.mergeCachedFeed(buildGoTransitTestFeed());
      transitModeService = TransitModeService(gtfsService);
    });

    test('evaluate exposes along-route remaining meters on GO line', () {
      const destination = Destination(
        name: 'Bronte GO',
        latitude: 43.4039,
        longitude: -79.7589,
      );

      final snapshot = transitModeService.evaluate(
        destination: destination,
        latitude: 43.4553,
        longitude: -79.6829,
        routeId: 'go_transit_lakeshore_west',
        maxStopProximityMeters: 1000,
        headingDegrees: 250,
        speedMps: 15,
      );

      expect(snapshot.isActive, isTrue);
      expect(snapshot.alongRouteRemainingMeters, isNotNull);
      expect(snapshot.offRouteMeters, isNotNull);
      expect(snapshot.alongRouteRemainingMeters!, greaterThan(0));
    });
  });

  group('GpsQualityGate', () {
    const gate = GpsQualityGate();

    test('rejects poor accuracy fixes', () {
      final poor = CurrentLocation(
        latitude: 43.6,
        longitude: -79.4,
        speed: 0,
        accuracy: 200,
        timestamp: _fixedTime,
      );

      expect(gate.accept(poor), isFalse);
    });

    test('accepts degraded accuracy when allowed', () {
      final degraded = CurrentLocation(
        latitude: 43.6,
        longitude: -79.4,
        speed: 0,
        accuracy: 120,
        timestamp: _fixedTime,
      );

      expect(gate.accept(degraded, allowDegraded: true), isTrue);
    });

    test('accepts bootstrap accuracy only via bootstrap gate', () {
      final bootstrap = CurrentLocation(
        latitude: 43.6,
        longitude: -79.4,
        speed: 0,
        accuracy: 180,
        timestamp: _fixedTime,
      );

      expect(gate.accept(bootstrap, allowDegraded: true), isFalse);
      expect(gate.acceptForBootstrap(bootstrap), isTrue);
    });
  });
}

final _fixedTime = DateTime(2026, 6, 18, 12);
