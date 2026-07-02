import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/models/background_transit_pattern.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/services/background_transit_evaluator.dart';

void main() {
  group('BackgroundTransitEvaluator', () {
    const stops = [
      TransitStop(
        stopId: 'route_a:d0:s1',
        stopName: 'Alpha',
        latitude: 43.65,
        longitude: -79.38,
        routeId: 'route_a',
        stopSequence: 1,
      ),
      TransitStop(
        stopId: 'route_a:d0:s2',
        stopName: 'Bravo',
        latitude: 43.66,
        longitude: -79.37,
        routeId: 'route_a',
        stopSequence: 2,
      ),
      TransitStop(
        stopId: 'route_a:d0:s3',
        stopName: 'Charlie',
        latitude: 43.67,
        longitude: -79.36,
        routeId: 'route_a',
        stopSequence: 3,
      ),
    ];

    final pattern = BackgroundTransitPattern(
      routeId: 'route_a',
      directionLocked: true,
      travelingForward: true,
      destinationStopSequence: 3,
      stabilizedStopSequence: 1,
      segmentStops: stops,
    );

    test('counts stops remaining from GPS near current stop', () {
      final evaluator = BackgroundTransitEvaluator();
      final result = evaluator.evaluate(
        pattern: pattern,
        latitude: 43.6505,
        longitude: -79.3795,
      );

      expect(result, isNotNull);
      expect(result!.onRoute, isTrue);
      expect(result.stopsRemaining, 2);
      expect(result.directionLocked, isTrue);
    });
  });
}
