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
        latitude: segmentStops[2].latitude,
        longitude: segmentStops[2].longitude,
      );

      expect(decision.shouldTrigger, isTrue);
      expect(decision.reason, TransitWakeDecisionReason.recoveredAfterStopJump);
    });

    test(
      'train does not fire 1.5km before wake stop when along-route looks early',
      () {
        // Bronte → Oakville → Clarkson style spacing (~5 km wake→dest chords
        // omitted; plan stores wakeToDestinationMeters=5000).
        final lakeshore = [
          const TransitStop(
            stopId: 'bronte',
            stopName: 'Bronte GO',
            latitude: 43.4165,
            longitude: -79.7220,
            routeId: routeId,
            stopSequence: 10,
          ),
          const TransitStop(
            stopId: 'oakville',
            stopName: 'Oakville GO',
            latitude: 43.4550,
            longitude: -79.6820,
            routeId: routeId,
            stopSequence: 20,
          ),
          const TransitStop(
            stopId: 'clarkson',
            stopName: 'Clarkson GO',
            latitude: 43.5067,
            longitude: -79.6350,
            routeId: routeId,
            stopSequence: 30,
          ),
        ];
        final oakvillePlan = TransitWakePlan(
          routeId: routeId,
          patternKey: 'lakeshore-east',
          wakeStopCount: 1,
          destinationStopSequence: 30,
          wakeStopSequence: 20,
          wakeToDestinationMeters: 6500,
          segmentStops: lakeshore,
          travelingForward: true,
          vehicleType: TransitVehicleType.train,
        );

        // Optimistic along-route remaining (as if at Oakville) while GPS is
        // still ~1.5 km southwest of Oakville — between Bronte and Oakville.
        final decision = TransitWakeTrigger.evaluatePlan(
          plan: oakvillePlan,
          directionLocked: true,
          hasEstablishedProgress: true,
          hasTripConcern: false,
          currentStop: lakeshore[1],
          alongRouteRemainingMeters: 6400,
          offRouteMeters: 25,
          accuracyMeters: 20,
          gpsStale: false,
          armedAt: DateTime(2026, 8, 13, 8),
          armStableFixes: TransitWakeTrigger.minStableArmFixes,
          latitude: 43.4450,
          longitude: -79.6950,
        );

        expect(decision.shouldTrigger, isFalse);
        expect(
          decision.reason,
          TransitWakeDecisionReason.armedWaitingForWakeProximity,
        );
      },
    );

    test('train fires when near the wake stop itself', () {
      final lakeshore = [
        const TransitStop(
          stopId: 'bronte',
          stopName: 'Bronte GO',
          latitude: 43.4165,
          longitude: -79.7220,
          routeId: routeId,
          stopSequence: 10,
        ),
        const TransitStop(
          stopId: 'oakville',
          stopName: 'Oakville GO',
          latitude: 43.4550,
          longitude: -79.6820,
          routeId: routeId,
          stopSequence: 20,
        ),
        const TransitStop(
          stopId: 'clarkson',
          stopName: 'Clarkson GO',
          latitude: 43.5067,
          longitude: -79.6350,
          routeId: routeId,
          stopSequence: 30,
        ),
      ];
      final oakvillePlan = TransitWakePlan(
        routeId: routeId,
        patternKey: 'lakeshore-east',
        wakeStopCount: 1,
        destinationStopSequence: 30,
        wakeStopSequence: 20,
        wakeToDestinationMeters: 6500,
        segmentStops: lakeshore,
        travelingForward: true,
        vehicleType: TransitVehicleType.train,
      );

      final decision = TransitWakeTrigger.evaluatePlan(
        plan: oakvillePlan,
        directionLocked: true,
        hasEstablishedProgress: true,
        hasTripConcern: false,
        currentStop: lakeshore[1],
        alongRouteRemainingMeters: 6400,
        offRouteMeters: 25,
        accuracyMeters: 20,
        gpsStale: false,
        armedAt: DateTime(2026, 8, 13, 8),
        armStableFixes: TransitWakeTrigger.minStableArmFixes,
        latitude: lakeshore[1].latitude,
        longitude: lakeshore[1].longitude,
      );

      expect(decision.shouldTrigger, isTrue);
      expect(decision.reason, TransitWakeDecisionReason.confirmedByDistance);
    });

    test('train needs stable arm fixes before distance confirm', () {
      final lakeshore = [
        const TransitStop(
          stopId: 'oakville',
          stopName: 'Oakville GO',
          latitude: 43.4550,
          longitude: -79.6820,
          routeId: routeId,
          stopSequence: 20,
        ),
        const TransitStop(
          stopId: 'clarkson',
          stopName: 'Clarkson GO',
          latitude: 43.5067,
          longitude: -79.6350,
          routeId: routeId,
          stopSequence: 30,
        ),
      ];
      final oakvillePlan = TransitWakePlan(
        routeId: routeId,
        patternKey: 'lakeshore-east',
        wakeStopCount: 1,
        destinationStopSequence: 30,
        wakeStopSequence: 20,
        wakeToDestinationMeters: 6500,
        segmentStops: [
          const TransitStop(
            stopId: 'bronte',
            stopName: 'Bronte GO',
            latitude: 43.4165,
            longitude: -79.7220,
            routeId: routeId,
            stopSequence: 10,
          ),
          ...lakeshore,
        ],
        travelingForward: true,
        vehicleType: TransitVehicleType.train,
      );

      final decision = TransitWakeTrigger.evaluatePlan(
        plan: oakvillePlan,
        directionLocked: true,
        hasEstablishedProgress: true,
        hasTripConcern: false,
        currentStop: lakeshore[0],
        alongRouteRemainingMeters: 6400,
        offRouteMeters: 25,
        accuracyMeters: 20,
        gpsStale: false,
        armedAt: null,
        armStableFixes: 0,
        latitude: lakeshore[0].latitude,
        longitude: lakeshore[0].longitude,
      );

      expect(decision.shouldTrigger, isFalse);
      expect(decision.isArmed, isTrue);
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
        armStableFixes: 4,
        now: armedAt.add(const Duration(seconds: 45)),
        // Near the wake stop — poor-GPS must not fire while far away.
        latitude: segmentStops[1].latitude,
        longitude: segmentStops[1].longitude,
      );

      expect(decision.shouldTrigger, isTrue);
      expect(
        decision.reason,
        TransitWakeDecisionReason.confirmedByPoorGpsFallback,
      );
    });

    test('poor-GPS fallback does not fire far from the train wake stop', () {
      final lakeshore = [
        const TransitStop(
          stopId: 'bronte',
          stopName: 'Bronte GO',
          latitude: 43.4165,
          longitude: -79.7220,
          routeId: routeId,
          stopSequence: 10,
        ),
        const TransitStop(
          stopId: 'oakville',
          stopName: 'Oakville GO',
          latitude: 43.4550,
          longitude: -79.6820,
          routeId: routeId,
          stopSequence: 20,
        ),
        const TransitStop(
          stopId: 'clarkson',
          stopName: 'Clarkson GO',
          latitude: 43.5067,
          longitude: -79.6350,
          routeId: routeId,
          stopSequence: 30,
        ),
      ];
      final oakvillePlan = TransitWakePlan(
        routeId: routeId,
        patternKey: 'lakeshore-east',
        wakeStopCount: 1,
        destinationStopSequence: 30,
        wakeStopSequence: 20,
        wakeToDestinationMeters: 6500,
        segmentStops: lakeshore,
        travelingForward: true,
        vehicleType: TransitVehicleType.train,
      );
      final armedAt = DateTime(2026, 7, 17, 12);
      final decision = TransitWakeTrigger.evaluatePlan(
        plan: oakvillePlan,
        directionLocked: true,
        hasEstablishedProgress: true,
        hasTripConcern: false,
        currentStop: lakeshore[1],
        alongRouteRemainingMeters: null,
        offRouteMeters: null,
        accuracyMeters: 0,
        gpsStale: true,
        armedAt: armedAt,
        armStableFixes: 4,
        now: armedAt.add(const Duration(seconds: 45)),
        latitude: lakeshore[0].latitude,
        longitude: lakeshore[0].longitude,
      );

      expect(decision.shouldTrigger, isFalse);
      expect(
        decision.reason,
        TransitWakeDecisionReason.armedWaitingForGpsGrace,
      );
    });

    test(
      'at destination fires at the platform even when along-route remaining is 2km',
      () {
        // Field: Bronte GO, At destination, standing at the station, UI still
        // showed ~2.3 km remaining (GTFS shape hinterland) and never alarmed.
        final lakeshore = [
          const TransitStop(
            stopId: 'oakville',
            stopName: 'Oakville GO',
            latitude: 43.4550,
            longitude: -79.6820,
            routeId: routeId,
            stopSequence: 20,
          ),
          const TransitStop(
            stopId: 'bronte',
            stopName: 'Bronte GO',
            latitude: 43.4165,
            longitude: -79.7220,
            routeId: routeId,
            stopSequence: 30,
          ),
        ];
        final destPlan = TransitWakePlan(
          routeId: routeId,
          patternKey: 'lakeshore-west',
          wakeStopCount: 0,
          destinationStopSequence: 30,
          wakeStopSequence: 30,
          wakeToDestinationMeters: 0,
          segmentStops: lakeshore,
          travelingForward: true,
          vehicleType: TransitVehicleType.train,
        );

        final decision = TransitWakeTrigger.evaluatePlan(
          plan: destPlan,
          directionLocked: true,
          hasEstablishedProgress: true,
          hasTripConcern: false,
          currentStop: lakeshore[1],
          alongRouteRemainingMeters: 2300,
          offRouteMeters: 20,
          accuracyMeters: 15,
          gpsStale: false,
          armedAt: DateTime(2026, 8, 19, 17, 29),
          armStableFixes: TransitWakeTrigger.minStableArmFixes,
          latitude: lakeshore[1].latitude,
          longitude: lakeshore[1].longitude,
        );

        expect(decision.shouldTrigger, isTrue);
        expect(decision.reason, TransitWakeDecisionReason.confirmedByDistance);
      },
    );

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
