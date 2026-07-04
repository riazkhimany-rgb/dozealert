import 'package:dozealert/models/transit_mode_snapshot.dart';
import 'package:dozealert/models/transit_mode_wake_setting.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/utils/transit_wake_message.dart';
import 'package:flutter_test/flutter_test.dart';

TransitStop _stop(String name, int sequence) {
  return TransitStop(
    stopId: name,
    stopName: name,
    latitude: 0,
    longitude: 0,
    routeId: 'route',
    stopSequence: sequence,
  );
}

TransitModeSnapshot _snapshot({
  required TransitStop destination,
  required int stopsRemaining,
  TransitStop? nextStop,
}) {
  return TransitModeSnapshot(
    isActive: true,
    destinationStop: destination,
    currentStop: _stop('Current', destination.stopSequence - stopsRemaining),
    nextStop: nextStop,
    stopsRemaining: stopsRemaining,
  );
}

void main() {
  group('TransitWakeMessage.forTransitAlarm', () {
    final destination = _stop('Union Station', 10);
    final segment = [
      _stop('King', 8),
      _stop('Queen', 9),
      destination,
    ];

    test('at destination points to the destination stop', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(destination: destination, stopsRemaining: 0),
        wakeSetting: TransitModeWakeSetting.atDestination,
        segmentStops: segment,
      );

      expect(copy.headline, 'Arriving at Union Station');
      expect(copy.primaryStopName, 'Union Station');
      expect(copy.secondaryLine, isNull);
      expect(copy.wearSubline, 'Time to get off');
      expect(copy.detailMessage, contains('Your stop Union Station is here'));
      expect(copy.detailMessage, isNot(contains('Distance wake')));
    });

    test('one stop before still points to the destination, not an earlier stop',
        () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(
          destination: destination,
          stopsRemaining: 1,
          nextStop: _stop('Queen', 9),
        ),
        wakeSetting: TransitModeWakeSetting.oneStopBefore,
        segmentStops: segment,
      );

      expect(copy.headline, 'Union Station — 1 stop to go');
      expect(copy.primaryStopName, 'Union Station');
      expect(copy.secondaryLine, 'Stay on until Union Station');
      expect(copy.wearSubline, '1 stop to go');
      // Must not instruct the rider to get off at the earlier wake stop.
      expect(copy.detailMessage, contains('Get ready to get off at Union Station'));
      expect(copy.detailMessage, isNot(contains('Queen')));
      expect(copy.ttsPhrase, contains('Union Station'));
      expect(copy.ttsPhrase, isNot(contains('Queen')));
    });

    test('two stops before still points to the destination', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(
          destination: destination,
          stopsRemaining: 2,
          nextStop: _stop('King', 8),
        ),
        wakeSetting: TransitModeWakeSetting.twoStopsBefore,
        segmentStops: segment,
      );

      expect(copy.headline, 'Union Station — 2 stops to go');
      expect(copy.primaryStopName, 'Union Station');
      expect(copy.secondaryLine, 'Stay on until Union Station');
      expect(copy.wearSubline, '2 stops to go');
      expect(copy.detailMessage, isNot(contains('King')));
    });
  });

  group('TransitWakeMessage.forDistanceAlarm', () {
    test('distance wake copy is distinct from stop wake', () {
      final copy = TransitWakeMessage.forDistanceAlarm(
        destinationName: 'Union Station',
      );

      expect(copy.headline, 'Approaching Union Station');
      expect(copy.detailMessage, contains('Distance wake'));
      expect(copy.wearSubline, 'Within wake radius');
    });
  });
}
