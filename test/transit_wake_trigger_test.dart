import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/utils/transit_wake_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const routeId = 'route';
  final segmentStops = [
    const TransitStop(
      stopId: 'james-snow',
      stopName: 'James Snow Pkwy',
      latitude: 43.5,
      longitude: -79.7,
      routeId: routeId,
      stopSequence: 1,
    ),
    const TransitStop(
      stopId: 'trudeau',
      stopName: 'Trudeau Dr',
      latitude: 43.501,
      longitude: -79.701,
      routeId: routeId,
      stopSequence: 2,
    ),
    const TransitStop(
      stopId: 'fourth-line',
      stopName: 'Fourth Line',
      latitude: 43.502,
      longitude: -79.702,
      routeId: routeId,
      stopSequence: 3,
    ),
  ];

  group('TransitWakeTrigger.shouldTrigger', () {
    test('does not wake two stops early when setting is one stop before', () {
      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 2,
          wakeStopCount: 1,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 200,
          offRouteMeters: 20,
          accuracyMeters: 15,
          speedMps: 8,
          segmentStops: segmentStops,
          currentStop: segmentStops[0],
          destinationStop: segmentStops[2],
        ),
        isFalse,
      );
    });

    test('wakes at the configured wake stop when near along route', () {
      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 1,
          wakeStopCount: 1,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 100,
          offRouteMeters: 15,
          accuracyMeters: 12,
          speedMps: 6,
          segmentStops: segmentStops,
          currentStop: segmentStops[1],
          destinationStop: segmentStops[2],
        ),
        isTrue,
      );
    });

    test('does not wake when stop sequence advanced but still far along route', () {
      final wakeToDestination = TransitWakeTrigger.alongRouteMetersBetweenStops(
        segmentStops: segmentStops,
        fromStop: segmentStops[1],
        toStop: segmentStops[2],
        destinationStop: segmentStops[2],
      );

      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 1,
          wakeStopCount: 1,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: (wakeToDestination ?? 0) + 500,
          offRouteMeters: 15,
          accuracyMeters: 12,
          speedMps: 30,
          segmentStops: segmentStops,
          currentStop: segmentStops[1],
          destinationStop: segmentStops[2],
          vehicleType: TransitVehicleType.train,
        ),
        isFalse,
      );
    });

    test('does not wake at wake stop count alone when current stop is too early', () {
      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 1,
          wakeStopCount: 1,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 100,
          offRouteMeters: 15,
          accuracyMeters: 12,
          speedMps: 6,
          segmentStops: segmentStops,
          currentStop: segmentStops[0],
          destinationStop: segmentStops[2],
        ),
        isFalse,
      );
    });

    test('wakes two stops before at the first segment stop when near along route', () {
      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 2,
          wakeStopCount: 2,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 300,
          offRouteMeters: 20,
          accuracyMeters: 12,
          speedMps: 6,
          segmentStops: segmentStops,
          currentStop: segmentStops[0],
          destinationStop: segmentStops[2],
        ),
        isTrue,
      );
    });

    test('at destination wakes only when at destination along route', () {
      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 0,
          wakeStopCount: 0,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 50,
          offRouteMeters: 10,
          accuracyMeters: 12,
          speedMps: 0,
          segmentStops: segmentStops,
          currentStop: segmentStops[2],
          destinationStop: segmentStops[2],
        ),
        isTrue,
      );

      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 1,
          wakeStopCount: 0,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 100,
          offRouteMeters: 10,
          accuracyMeters: 12,
          speedMps: 8,
          segmentStops: segmentStops,
          currentStop: segmentStops[1],
          destinationStop: segmentStops[2],
        ),
        isFalse,
      );

      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 2,
          wakeStopCount: 0,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 500,
          offRouteMeters: 20,
          accuracyMeters: 12,
          speedMps: 8,
          segmentStops: segmentStops,
          currentStop: segmentStops[0],
          destinationStop: segmentStops[2],
        ),
        isFalse,
      );
    });

    test('wakes on short segment when at the implicit wake stop', () {
      final shortSegment = [
        segmentStops[1],
        segmentStops[2],
      ];

      expect(
        TransitWakeTrigger.shouldTrigger(
          stopsRemaining: 1,
          wakeStopCount: 2,
          directionLocked: true,
          hasEstablishedProgress: true,
          alongRouteRemainingMeters: 100,
          offRouteMeters: 15,
          accuracyMeters: 12,
          speedMps: 6,
          segmentStops: shortSegment,
          currentStop: shortSegment[0],
          destinationStop: shortSegment[1],
        ),
        isTrue,
      );
    });
  });
}
