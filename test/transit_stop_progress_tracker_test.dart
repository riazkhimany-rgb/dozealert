import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/services/transit_stop_progress_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransitStopProgressTracker', () {
    const routeId = 'test_route';
    const destination = TransitStop(
      stopId: '5',
      stopName: 'Destination',
      latitude: 0,
      longitude: 0,
      routeId: routeId,
      stopSequence: 5,
    );

    final routeStops = [
      const TransitStop(
        stopId: '1',
        stopName: 'A',
        latitude: 0,
        longitude: 0,
        routeId: routeId,
        stopSequence: 1,
      ),
      const TransitStop(
        stopId: '2',
        stopName: 'B',
        latitude: 0,
        longitude: 0,
        routeId: routeId,
        stopSequence: 2,
      ),
      const TransitStop(
        stopId: '3',
        stopName: 'C',
        latitude: 0,
        longitude: 0,
        routeId: routeId,
        stopSequence: 3,
      ),
      const TransitStop(
        stopId: '4',
        stopName: 'D',
        latitude: 0,
        longitude: 0,
        routeId: routeId,
        stopSequence: 4,
      ),
      destination,
    ];

    late TransitStopProgressTracker tracker;

    setUp(() {
      tracker = TransitStopProgressTracker();
    });

    test('accepts first lock on a new route', () {
      final result = tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[2],
        routeStops: routeStops,
      );

      expect(result.stopName, 'C');
    });

    test('rejects skipping ahead more than one stop', () {
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[1],
        routeStops: routeStops,
      );

      final skipped = tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[3],
        routeStops: routeStops,
      );

      expect(skipped.stopName, 'B');
    });

    test('advances one stop at a time toward destination', () {
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[1],
        routeStops: routeStops,
      );

      final next = tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[2],
        routeStops: routeStops,
      );

      expect(next.stopName, 'C');
    });

    test('allows one-stop backward correction', () {
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[2],
        routeStops: routeStops,
      );

      final corrected = tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[1],
        routeStops: routeStops,
      );

      expect(corrected.stopName, 'B');
    });

    test('resets when route or destination changes', () {
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[2],
        routeStops: routeStops,
      );

      const otherDestination = TransitStop(
        stopId: '4',
        stopName: 'D',
        latitude: 0,
        longitude: 0,
        routeId: routeId,
        stopSequence: 4,
      );

      final fresh = tracker.reconcile(
        routeId: routeId,
        destinationStop: otherDestination,
        rawStop: routeStops[3],
        routeStops: routeStops,
      );

      expect(fresh.stopName, 'D');
    });
  });
}
