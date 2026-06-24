import 'package:dozealert/models/current_location.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/route_geometry_service.dart';
import 'package:dozealert/services/transit_data_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';
import 'package:dozealert/utils/gps_quality.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });

  group('TransitModeService geometry integration', () {
    late GtfsService gtfsService;
    late TransitModeService transitModeService;

    setUp(() async {
      gtfsService = GtfsService(TransitDataService());
      await gtfsService.initializeFromFallbackData();
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
  });
}

final _fixedTime = DateTime(2026, 6, 18, 12);
