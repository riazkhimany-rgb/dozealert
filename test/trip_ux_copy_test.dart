import 'package:dozealert/utils/trip_ux_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripUxCopy.transitProgressLabel', () {
    test('does not claim arrival while meaningful route distance remains', () {
      expect(
        TripUxCopy.transitProgressLabel(
          stopsRemaining: 0,
          alongRouteRemainingMeters: 1500,
        ),
        'Approaching destination',
      );
    });

    test('shows destination once remaining route distance is small', () {
      expect(
        TripUxCopy.transitProgressLabel(
          stopsRemaining: 0,
          alongRouteRemainingMeters: 100,
        ),
        'At destination stop',
      );
    });
  });
}
