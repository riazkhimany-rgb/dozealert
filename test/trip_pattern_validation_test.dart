import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/models/trip_pattern_concern.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/utils/trip_pattern_validation.dart';

void main() {
  const pattern = [
    TransitStop(
      stopId: 'r:d0:s1',
      stopName: 'A',
      latitude: 0,
      longitude: 0,
      routeId: 'r',
      stopSequence: 1,
    ),
    TransitStop(
      stopId: 'r:d0:s2',
      stopName: 'B',
      latitude: 0,
      longitude: 0,
      routeId: 'r',
      stopSequence: 2,
    ),
    TransitStop(
      stopId: 'r:d0:s3',
      stopName: 'C',
      latitude: 0,
      longitude: 0,
      routeId: 'r',
      stopSequence: 3,
    ),
    TransitStop(
      stopId: 'r:d0:s4',
      stopName: 'D',
      latitude: 0,
      longitude: 0,
      routeId: 'r',
      stopSequence: 4,
    ),
  ];

  test('flags wrong direction when destination is behind current', () {
    final result = validateTripOnPattern(
      pattern: pattern,
      current: pattern[3],
      destination: pattern[0],
      patternKey: 'd:0',
      directionLocked: true,
    );

    expect(result.concern, TripPatternConcern.wrongDirection);
  });

  test('never flags a concern once the rider is near the destination', () {
    final result = validateTripOnPattern(
      pattern: pattern,
      current: pattern[3],
      destination: pattern[0],
      patternKey: 'd:0',
      directionLocked: true,
      alongRouteRemainingMeters: 120,
    );

    expect(result.concern, isNull);
  });

  test('ignores a single stop of overshoot as GPS noise', () {
    final result = validateTripOnPattern(
      pattern: pattern,
      current: pattern[1],
      destination: pattern[0],
      patternKey: 'd:0',
      directionLocked: true,
      alongRouteRemainingMeters: 2000,
    );

    expect(result.concern, isNull);
  });

  test('does not emit a label for a raw direction_id pattern key', () {
    final result = validateTripOnPattern(
      pattern: pattern,
      current: pattern[0],
      destination: pattern[3],
      patternKey: 'd:0',
      directionLocked: true,
    );

    expect(result.directionLabel, isNull);
  });

  test('uses pending pattern key for direction label before lock', () {
    final result = validateTripOnPattern(
      pattern: pattern,
      current: pattern[0],
      destination: pattern[3],
      patternKey: 'd:0',
      directionLocked: false,
      pendingPatternKey: 'h:finch',
    );

    expect(result.directionLabel, 'finch');
  });

  test('does not flag a long forward trip as a concern', () {
    final longPattern = List<TransitStop>.generate(
      20,
      (index) => TransitStop(
        stopId: 'r:d0:s$index',
        stopName: 'Stop $index',
        latitude: 0,
        longitude: 0,
        routeId: 'r',
        stopSequence: index + 1,
      ),
    );

    final result = validateTripOnPattern(
      pattern: longPattern,
      current: longPattern.first,
      destination: longPattern.last,
      patternKey: 'd:0',
      directionLocked: true,
    );

    expect(result.concern, isNull);
  });
}
