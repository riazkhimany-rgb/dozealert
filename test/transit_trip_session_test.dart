import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/services/transit_trip_session.dart';

void main() {
  test('locks direction after consistent fixes', () {
    final session = TransitTripSession();

    expect(
      session.updateAndGetPatternKey(
        routeId: 'route_a',
        destinationKey: 'dest_1',
        inferredPatternKey: 'd:0',
      ),
      'd:0',
    );
    expect(session.isDirectionLocked, isFalse);

    session.updateAndGetPatternKey(
      routeId: 'route_a',
      destinationKey: 'dest_1',
      inferredPatternKey: 'd:0',
    );
    session.updateAndGetPatternKey(
      routeId: 'route_a',
      destinationKey: 'dest_1',
      inferredPatternKey: 'd:0',
    );

    expect(session.isDirectionLocked, isTrue);
    expect(session.lockedPatternKey, 'd:0');
  });

  test('seed marks as seeded but not locked (pending confirmation)', () {
    final session = TransitTripSession()
      ..seedPatternKey(
        routeId: 'route_a',
        destinationKey: 'union',
        patternKey: 'd:1',
      );

    // Seeded but not yet locked — GPS must confirm.
    expect(session.isSeeded, isTrue);
    expect(session.isDirectionLocked, isFalse);
    expect(session.lockedPatternKey, isNull);

    // A single confirming GPS fix promotes the seed to locked.
    final key = session.updateAndGetPatternKey(
      routeId: 'route_a',
      destinationKey: 'union',
      inferredPatternKey: 'd:1',
    );
    expect(key, 'd:1');
    expect(session.isDirectionLocked, isTrue);
    expect(session.lockedPatternKey, 'd:1');
  });

  test('seed is overridden when GPS consistently infers a different direction',
      () {
    final session = TransitTripSession()
      ..seedPatternKey(
        routeId: 'route_a',
        destinationKey: 'union',
        patternKey: 'd:1',
      );

    // GPS disagrees — direction resets to the GPS-inferred pattern.
    session.updateAndGetPatternKey(
      routeId: 'route_a',
      destinationKey: 'union',
      inferredPatternKey: 'd:0',
    );
    expect(session.isDirectionLocked, isFalse);

    session.updateAndGetPatternKey(
      routeId: 'route_a',
      destinationKey: 'union',
      inferredPatternKey: 'd:0',
    );
    session.updateAndGetPatternKey(
      routeId: 'route_a',
      destinationKey: 'union',
      inferredPatternKey: 'd:0',
    );
    expect(session.isDirectionLocked, isTrue);
    expect(session.lockedPatternKey, 'd:0');
  });

  test('re-locks onto a new direction after GPS consistently disagrees', () {
    final session = TransitTripSession();

    // Lock onto d:0 first (the wrong direction, e.g. from an early guess).
    for (var i = 0; i < TransitTripSession.lockFixCount; i++) {
      session.updateAndGetPatternKey(
        routeId: 'route_a',
        destinationKey: 'dest_1',
        inferredPatternKey: 'd:0',
      );
    }
    expect(session.lockedPatternKey, 'd:0');

    // GPS now consistently reports the opposite direction — the lock must
    // self-correct rather than staying wrong for the whole trip.
    String? key;
    for (var i = 0; i < TransitTripSession.lockFixCount; i++) {
      key = session.updateAndGetPatternKey(
        routeId: 'route_a',
        destinationKey: 'dest_1',
        inferredPatternKey: 'd:1',
      );
    }

    expect(key, 'd:1');
    expect(session.lockedPatternKey, 'd:1');
  });

  test('resets when route or destination changes', () {
    final session = TransitTripSession()
      ..updateAndGetPatternKey(
        routeId: 'route_a',
        destinationKey: 'dest_1',
        inferredPatternKey: 'd:1',
      )
      ..updateAndGetPatternKey(
        routeId: 'route_a',
        destinationKey: 'dest_1',
        inferredPatternKey: 'd:1',
      )
      ..updateAndGetPatternKey(
        routeId: 'route_a',
        destinationKey: 'dest_1',
        inferredPatternKey: 'd:1',
      );

    expect(session.isDirectionLocked, isTrue);

    session.updateAndGetPatternKey(
      routeId: 'route_a',
      destinationKey: 'dest_2',
      inferredPatternKey: 'd:0',
    );

    expect(session.isDirectionLocked, isFalse);
    expect(session.lockedPatternKey, isNull);
  });
}
