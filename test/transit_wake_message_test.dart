import 'package:dozealert/models/transit_mode_snapshot.dart';
import 'package:dozealert/models/transit_mode_wake_setting.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/utils/transit_wake_message.dart';
import 'package:dozealert/utils/trip_ux_copy.dart';
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
  TransitStop? currentStop,
  TransitStop? nextStop,
}) {
  return TransitModeSnapshot(
    isActive: true,
    destinationStop: destination,
    currentStop: currentStop ??
        _stop('Current', destination.stopSequence - stopsRemaining),
    nextStop: nextStop,
    stopsRemaining: stopsRemaining,
  );
}

void main() {
  group('AlarmTtsCopy', () {
    test('transit at destination names the stop', () {
      expect(
        AlarmTtsCopy.transitAtDestination('Bronte GO'),
        'Heads up! Your stop Bronte GO is here.',
      );
    });

    test('transit one stop away uses singular phrasing', () {
      expect(
        AlarmTtsCopy.transitStopsAway(
          destinationName: 'Union Station',
          stopsLeft: 1,
        ),
        'Heads up! Get ready to get off at Union Station, one stop away.',
      );
    });

    test('transit multiple stops away includes count', () {
      expect(
        AlarmTtsCopy.transitStopsAway(
          destinationName: 'Union Station',
          stopsLeft: 2,
        ),
        contains('2 stops away'),
      );
    });
  });

  group('TransitWakeMessage.forTransitAlarm', () {
    final destination = _stop('Union Station', 10);
    final queen = _stop('Queen', 9);
    final segment = [
      _stop('King', 8),
      queen,
      destination,
    ];

    test('at destination uses time-to-get-off headline and destination line', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(
          destination: destination,
          stopsRemaining: 0,
          currentStop: destination,
        ),
        wakeSetting: TransitModeWakeSetting.atDestination,
        segmentStops: segment,
      );

      expect(copy.uiHeadline, TripUxCopy.timeToGetOffHeadline);
      expect(copy.headline, 'Union Station is your stop');
      expect(copy.primaryStopName, 'Union Station');
      expect(copy.currentStopName, 'Union Station');
      expect(copy.secondaryLine, isNull);
      expect(copy.wearSubline, 'Time to get off');
      expect(copy.detailMessage, TripUxCopy.alarmContinuesUntilDismiss);
    });

    test('one stop before shows get ready copy and current stop', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(
          destination: destination,
          stopsRemaining: 1,
          currentStop: queen,
          nextStop: destination,
        ),
        wakeSetting: TransitModeWakeSetting.oneStopBefore,
        segmentStops: segment,
      );

      expect(copy.uiHeadline, TripUxCopy.getReadyHeadline);
      expect(copy.headline, 'Union Station is your stop');
      expect(copy.primaryStopName, 'Union Station');
      expect(copy.currentStopName, 'Queen');
      expect(copy.secondaryLine, TripUxCopy.stayOnBoard);
      expect(copy.wearSubline, '1 more stop to go');
      expect(copy.ttsPhrase, contains('Union Station'));
      expect(copy.ttsPhrase, isNot(contains('Queen')));
    });

    test('caps inflated stop count for one-stop-before wake', () {
      final copy = TransitWakeMessage.forTransitAlarm(
        snapshot: _snapshot(
          destination: destination,
          stopsRemaining: 2,
          currentStop: segment[0],
          nextStop: segment[1],
        ),
        wakeSetting: TransitModeWakeSetting.oneStopBefore,
        segmentStops: segment,
      );

      expect(copy.wearSubline, '1 more stop to go');
      expect(copy.secondaryLine, TripUxCopy.stayOnBoard);
      expect(copy.ttsPhrase, contains('one stop away'));
    });

    test('stopsLeftForAlarmDisplay leaves at-destination counts unchanged', () {
      expect(
        TransitWakeMessage.stopsLeftForAlarmDisplay(
          stopsRemaining: 2,
          wakeSetting: TransitModeWakeSetting.atDestination,
        ),
        2,
      );
    });

    test('wearAlarmFieldsForWake caps inflated stop count for watch sync', () {
      final fields = TransitWakeMessage.wearAlarmFieldsForWake(
        stopsRemaining: 2,
        wakeSetting: TransitModeWakeSetting.oneStopBefore,
        destinationName: 'Union Station',
      );

      expect(fields.uiHeadline, TripUxCopy.getReadyHeadline);
      expect(fields.headline, 'Union Station is your stop');
      expect(fields.subline, '1 more stop to go');
      expect(fields.stopName, 'Union Station');
    });
  });

  group('TransitWakeMessage.forDistanceAlarm', () {
    test('distance wake uses get ready copy and generic footer', () {
      final copy = TransitWakeMessage.forDistanceAlarm(
        destinationName: 'Union Station',
      );

      expect(copy.uiHeadline, TripUxCopy.getReadyHeadline);
      expect(copy.headline, 'Union Station is your stop');
      expect(copy.detailMessage, TripUxCopy.alarmContinuesUntilDismiss);
      expect(copy.wearSubline, 'Within alert distance');
    });
  });
}
