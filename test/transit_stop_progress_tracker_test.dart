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

    test('advances two stops when maxStepsPerFix is 2', () {
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[1],
        routeStops: routeStops,
      );

      final stepped = tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[3],
        routeStops: routeStops,
        maxStepsPerFix: 2,
      );

      expect(stepped.stopName, 'D');
    });

    test('advances only one stop toward a multi-stop-ahead raw fix', () {
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[1],
        routeStops: routeStops,
      );

      // Raw jumps from B (seq 2) to D (seq 4): advance a single stop to C
      // rather than the full jump, but never hold still (which used to freeze
      // the stop count).
      final stepped = tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[3],
        routeStops: routeStops,
      );

      expect(stepped.stopName, 'C');
    });

    test('never gets stuck when raw repeatedly jumps ahead', () {
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: routeStops[0],
        routeStops: routeStops,
      );

      // The rider's true position stays at the destination while GPS fixes are
      // sparse. Each fix must make forward progress until it reaches it.
      var latest = routeStops[0];
      for (var i = 0; i < 4; i++) {
        latest = tracker.reconcile(
          routeId: routeId,
          destinationStop: destination,
          rawStop: destination,
          routeStops: routeStops,
        );
      }

      expect(latest.stopName, 'Destination');
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

    test('converges back down when it has over-advanced by several stops', () {
      // Accept the destination (seq 5) first.
      tracker.reconcile(
        routeId: routeId,
        destinationStop: destination,
        rawStop: destination,
        routeStops: routeStops,
      );

      // GPS now consistently reports the rider is really back at A (seq 1).
      // Each fix must step one stop closer rather than being stuck ahead.
      var latest = destination;
      for (var i = 0; i < 4; i++) {
        latest = tracker.reconcile(
          routeId: routeId,
          destinationStop: destination,
          rawStop: routeStops[0],
          routeStops: routeStops,
        );
      }

      expect(latest.stopName, 'A');
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

    test('does not advance to a far rail stop when GPS is still near current', () {
      const bronte = TransitStop(
        stopId: 'bronte',
        stopName: 'Bronte GO',
        latitude: 43.4165,
        longitude: -79.7220,
        routeId: routeId,
        stopSequence: 10,
      );
      const oakville = TransitStop(
        stopId: 'oakville',
        stopName: 'Oakville GO',
        latitude: 43.4550,
        longitude: -79.6820,
        routeId: routeId,
        stopSequence: 20,
      );
      const clarkson = TransitStop(
        stopId: 'clarkson',
        stopName: 'Clarkson GO',
        latitude: 43.5067,
        longitude: -79.6350,
        routeId: routeId,
        stopSequence: 30,
      );
      final railStops = [bronte, oakville, clarkson];

      tracker.reconcile(
        routeId: routeId,
        destinationStop: clarkson,
        rawStop: bronte,
        routeStops: railStops,
      );

      // Raw match jumped to Oakville, but rider GPS is still near Bronte.
      final held = tracker.reconcile(
        routeId: routeId,
        destinationStop: clarkson,
        rawStop: oakville,
        routeStops: railStops,
        latitude: bronte.latitude,
        longitude: bronte.longitude,
        maxAdvanceDistanceMeters: 800,
      );

      expect(held.stopName, 'Bronte GO');
    });
  });
}
