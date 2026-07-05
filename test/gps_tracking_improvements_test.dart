import 'package:dozealert/utils/along_route_smoother.dart';
import 'package:dozealert/utils/gps_tracking_confidence.dart';
import 'package:dozealert/utils/rider_motion_rules.dart';
import 'package:dozealert/utils/transit_wake_trigger.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiderMotionRules with activity recognition', () {
    test('blocks relaxed progress when on foot', () {
      expect(
        RiderMotionRules.allowsRelaxedStopProgress(
          useActivityRecognition: true,
          activityInVehicle: false,
          activityOnFoot: true,
          directionLocked: true,
          offRouteMeters: 10,
          accuracyMeters: 12,
          speedMps: 0.5,
        ),
        isFalse,
      );
    });

    test('allows relaxed progress in vehicle with high confidence', () {
      expect(
        RiderMotionRules.allowsRelaxedStopProgress(
          useActivityRecognition: true,
          activityInVehicle: true,
          activityOnFoot: false,
          directionLocked: true,
          offRouteMeters: 10,
          accuracyMeters: 12,
          speedMps: 6,
        ),
        isTrue,
      );
    });

    test('blocks approach wake on foot even with good GPS', () {
      expect(
        RiderMotionRules.allowsApproachWake(
          useActivityRecognition: true,
          activityInVehicle: false,
          activityOnFoot: true,
          speedMps: 0.5,
        ),
        isFalse,
      );
    });

    test('speed overrides still activity for in-vehicle detection', () {
      expect(
        RiderMotionRules.resolvesInVehicle(
          useActivityRecognition: true,
          activityInVehicle: false,
          speedMps: 6,
        ),
        isTrue,
      );
      expect(
        RiderMotionRules.allowsApproachWake(
          useActivityRecognition: true,
          activityInVehicle: false,
          activityOnFoot: true,
          speedMps: 6,
        ),
        isTrue,
      );
    });

    test('unknown activity falls back to speed for on-foot', () {
      expect(
        RiderMotionRules.resolvesOnFoot(
          useActivityRecognition: true,
          activityInVehicle: null,
          activityOnFoot: null,
          speedMps: 0.5,
        ),
        isTrue,
      );
    });
  });

  group('RiderMotionRules without activity recognition', () {
    test('does not treat rider as on foot from activity alone', () {
      expect(
        RiderMotionRules.resolvesOnFoot(
          useActivityRecognition: false,
          activityInVehicle: false,
          activityOnFoot: true,
          speedMps: 0.5,
        ),
        isFalse,
      );
    });

    test('allows approach wake when activity recognition is off', () {
      expect(
        RiderMotionRules.allowsApproachWake(
          useActivityRecognition: false,
          activityInVehicle: false,
          activityOnFoot: true,
          speedMps: 0.5,
        ),
        isTrue,
      );
    });
  });

  group('AlongRouteKalmanFilter', () {
    test('smooths noisy remaining-distance measurements', () {
      final filter = AlongRouteKalmanFilter();
      final t0 = DateTime(2026, 1, 1, 12);

      final first = filter.filter(
        measuredRemainingMeters: 1000,
        accuracyMeters: 20,
        timestamp: t0,
        speedMps: 8,
      );
      final second = filter.filter(
        measuredRemainingMeters: 980,
        accuracyMeters: 18,
        timestamp: t0.add(const Duration(seconds: 5)),
        speedMps: 8,
      );

      expect(first, closeTo(1000, 0.1));
      expect(second, inInclusiveRange(940, 990));
    });

    test('ignores out-of-order timestamps', () {
      final filter = AlongRouteKalmanFilter();
      final t0 = DateTime(2026, 1, 1, 12);

      filter.filter(
        measuredRemainingMeters: 1000,
        accuracyMeters: 20,
        timestamp: t0,
      );
      final outOfOrder = filter.filter(
        measuredRemainingMeters: 500,
        accuracyMeters: 20,
        timestamp: t0.subtract(const Duration(seconds: 5)),
      );

      expect(outOfOrder, closeTo(1000, 0.1));
    });
  });

  group('GpsTrackingConfidence', () {
    test('requires in vehicle for high confidence', () {
      expect(
        GpsTrackingConfidence.isHigh(
          directionLocked: true,
          offRouteMeters: 30,
          accuracyMeters: 18,
          speedMps: 8,
          inVehicle: false,
        ),
        isFalse,
      );
    });
  });

  group('TransitWakeTrigger', () {
    const routeId = 'route';
    final segmentStops = [
      const TransitStop(
        stopId: '1',
        stopName: 'A',
        latitude: 0,
        longitude: 0,
        routeId: routeId,
        stopSequence: 1,
      ),
      const TransitStop(
        stopId: '2',
        stopName: 'B',
        latitude: 0,
        longitude: 0.001,
        routeId: routeId,
        stopSequence: 2,
      ),
      const TransitStop(
        stopId: '3',
        stopName: 'C',
        latitude: 0,
        longitude: 0.002,
        routeId: routeId,
        stopSequence: 3,
      ),
    ];

    test('does not approach-wake on foot', () {
      expect(
        TransitWakeTrigger.shouldTriggerApproachWake(
          stopsRemaining: 2,
          wakeStopCount: 1,
          alongRouteRemainingMeters: 300,
          offRouteMeters: 25,
          accuracyMeters: 12,
          speedMps: 0.5,
          segmentStops: segmentStops,
          currentStop: segmentStops[0],
          destinationStop: segmentStops[2],
          activityInVehicle: false,
          activityOnFoot: true,
        ),
        isFalse,
      );
    });
  });
}
