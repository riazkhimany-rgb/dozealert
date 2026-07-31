import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/models/transit_wake_plan.dart';
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

    test(
      'does not wake when stop sequence advanced but still far along route',
      () {
        final wakeToDestination =
            TransitWakeTrigger.alongRouteMetersBetweenStops(
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
      },
    );

    test(
      'does not wake at wake stop count alone when current stop is too early',
      () {
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
      },
    );

    test(
      'wakes two stops before at the first segment stop when near along route',
      () {
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
      },
    );

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
      final shortSegment = [segmentStops[1], segmentStops[2]];

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

  group('TransitWakeTrigger.evaluatePlan', () {
    final plan = TransitWakePlan(
      routeId: routeId,
      patternKey: 'eastbound',
      wakeStopCount: 1,
      destinationStopSequence: 3,
      wakeStopSequence: 2,
      wakeToDestinationMeters: 1000,
      segmentStops: segmentStops,
      travelingForward: true,
      vehicleType: TransitVehicleType.train,
    );

    test(
      'stop progress arms but distance confirmation prevents early wake',
      () {
        final decision = TransitWakeTrigger.evaluatePlan(
          plan: plan,
          directionLocked: true,
          hasEstablishedProgress: true,
          hasTripConcern: false,
          currentStop: segmentStops[1],
          alongRouteRemainingMeters: 1500,
          offRouteMeters: 20,
          accuracyMeters: 15,
          gpsStale: false,
          armedAt: null,
          armStableFixes: 0,
        );

        expect(decision.isArmed, isTrue);
        expect(decision.shouldTrigger, isFalse);
        expect(
          decision.reason,
          TransitWakeDecisionReason.armedWaitingForDistance,
        );
      },
    );

    test(
      'does not recover from stop jump while still far from destination',
      () {
        final decision = TransitWakeTrigger.evaluatePlan(
          plan: plan,
          directionLocked: true,
          hasEstablishedProgress: true,
          hasTripConcern: false,
          currentStop: segmentStops[2],
          alongRouteRemainingMeters: 1200,
          offRouteMeters: 20,
          accuracyMeters: 15,
          gpsStale: false,
          armedAt: null,
          armStableFixes: 0,
        );

        expect(decision.shouldTrigger, isFalse);
        expect(decision.isArmed, isTrue);
        expect(
          decision.reason,
          TransitWakeDecisionReason.armedWaitingForDistance,
        );
      },
    );

    test('recovers after progress jumps when near destination buffer', () {
      final decision = TransitWakeTrigger.evaluatePlan(
        plan: plan,
        directionLocked: true,
        hasEstablishedProgress: true,
        hasTripConcern: false,
        currentStop: segmentStops[2],
        alongRouteRemainingMeters: 80,
        offRouteMeters: 20,
        accuracyMeters: 15,
        gpsStale: false,
        armedAt: null,
        armStableFixes: 0,
      );

      expect(decision.shouldTrigger, isTrue);
      expect(decision.reason, TransitWakeDecisionReason.recoveredAfterStopJump);
    });

    test('aligns wake distance to stop-chord geometry for FGS', () {
      final shapeBiasedPlan = TransitWakePlan(
        routeId: routeId,
        patternKey: 'eastbound',
        wakeStopCount: 1,
        destinationStopSequence: 3,
        wakeStopSequence: 2,
        wakeToDestinationMeters: 5000,
        segmentStops: segmentStops,
        travelingForward: true,
        vehicleType: TransitVehicleType.train,
      );

      final aligned = TransitWakeTrigger.withStopChordWakeDistance(
        shapeBiasedPlan,
      );
      final chord = TransitWakeTrigger.alongRouteMetersBetweenStops(
        segmentStops: segmentStops,
        fromStop: segmentStops[1],
        toStop: segmentStops[2],
        destinationStop: segmentStops[2],
      );

      expect(aligned.wakeToDestinationMeters, closeTo(chord!, 1));
      expect(aligned.wakeToDestinationMeters, lessThan(5000));
    });

    test('uses stable armed stop after the train GPS grace period', () {
      final armedAt = DateTime(2026, 7, 17, 12);
      final decision = TransitWakeTrigger.evaluatePlan(
        plan: plan,
        directionLocked: true,
        hasEstablishedProgress: true,
        hasTripConcern: false,
        currentStop: segmentStops[1],
        alongRouteRemainingMeters: null,
        offRouteMeters: null,
        accuracyMeters: 0,
        gpsStale: true,
        armedAt: armedAt,
        armStableFixes: TransitWakeTrigger.minStableArmFixes,
        now: armedAt.add(const Duration(seconds: 45)),
      );

      expect(decision.shouldTrigger, isTrue);
      expect(
        decision.reason,
        TransitWakeDecisionReason.confirmedByPoorGpsFallback,
      );
    });

    test('trip concern blocks distance and poor-GPS confirmation', () {
      final decision = TransitWakeTrigger.evaluatePlan(
        plan: plan,
        directionLocked: true,
        hasEstablishedProgress: true,
        hasTripConcern: true,
        currentStop: segmentStops[2],
        alongRouteRemainingMeters: 100,
        offRouteMeters: 10,
        accuracyMeters: 10,
        gpsStale: false,
        armedAt: DateTime(2026, 7, 17, 12),
        armStableFixes: TransitWakeTrigger.minStableArmFixes,
      );

      expect(decision.shouldTrigger, isFalse);
      expect(decision.reason, TransitWakeDecisionReason.tripConcern);
    });
  });
}
