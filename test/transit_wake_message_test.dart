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

    test('at destination uses destination stop name', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(destination: destination, stopsRemaining: 0),
        wakeSetting: TransitModeWakeSetting.atDestination,
        segmentStops: segment,
      );

      expect(copy.headline, 'Your stop is coming up');
      expect(copy.primaryStopName, 'Union Station');
      expect(copy.secondaryLine, isNull);
      expect(copy.wearSubline, 'Arriving now');
      expect(copy.detailMessage, contains('Wake by stops'));
      expect(copy.detailMessage, isNot(contains('Distance wake')));
    });

    test('one stop before shows wake stop and final destination', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(
          destination: destination,
          stopsRemaining: 1,
          nextStop: _stop('Queen', 9),
        ),
        wakeSetting: TransitModeWakeSetting.oneStopBefore,
        segmentStops: segment,
      );

      expect(copy.headline, '1 stop before destination');
      expect(copy.primaryStopName, 'Queen');
      expect(copy.secondaryLine, 'Final stop: Union Station');
      expect(copy.wearSubline, '1 stop before Union Station');
      expect(copy.ttsPhrase, contains('Queen'));
    });

    test('two stops before uses segment stop two before destination', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(
          destination: destination,
          stopsRemaining: 2,
          nextStop: _stop('King', 8),
        ),
        wakeSetting: TransitModeWakeSetting.twoStopsBefore,
        segmentStops: segment,
      );

      expect(copy.headline, '2 stops before destination');
      expect(copy.primaryStopName, 'King');
      expect(copy.secondaryLine, 'Final stop: Union Station');
      expect(copy.wearSubline, '2 stops before Union Station');
    });
  });

  group('TransitWakeMessage.forDistanceAlarm', () {
    test('distance wake copy is distinct from stop wake', () {
      final copy = TransitWakeMessage.forDistanceAlarm(
        destinationName: 'Union Station',
      );

      expect(copy.headline, 'Approaching destination');
      expect(copy.detailMessage, contains('Distance wake'));
      expect(copy.wearSubline, 'Within wake radius');
    });
  });
}
