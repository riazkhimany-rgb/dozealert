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

  test('seeds direction immediately from destination pick', () {
    final session = TransitTripSession()
      ..seedPatternKey(
        routeId: 'route_a',
        destinationKey: 'union',
        patternKey: 'd:1',
      );

    expect(session.isDirectionLocked, isTrue);
    expect(session.isSeeded, isTrue);
    expect(session.lockedPatternKey, 'd:1');
    expect(
      session.updateAndGetPatternKey(
        routeId: 'route_a',
        destinationKey: 'union',
        inferredPatternKey: 'd:0',
      ),
      'd:1',
    );
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
