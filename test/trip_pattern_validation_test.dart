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

  test('flags unlikely route when too many stops remain', () {
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

    expect(result.concern, TripPatternConcern.unlikelyRoute);
  });
}
