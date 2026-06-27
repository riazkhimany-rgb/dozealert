import 'package:dozealert/utils/trip_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TripReadinessSnapshot is ready when every item is complete', () {
    const snapshot = TripReadinessSnapshot(
      items: [
        TripReadinessItem(
          issue: TripReadinessIssue.destination,
          label: 'Destination chosen',
          complete: true,
          actionLabel: 'Set destination',
        ),
        TripReadinessItem(
          issue: TripReadinessIssue.permissions,
          label: 'Location and notification access',
          complete: true,
          actionLabel: 'Fix permissions',
        ),
      ],
    );

    expect(snapshot.isReady, isTrue);
    expect(snapshot.completeCount, 2);
  });

  test('TripReadinessSnapshot stays blocked while any item is incomplete', () {
    const snapshot = TripReadinessSnapshot(
      items: [
        TripReadinessItem(
          issue: TripReadinessIssue.destination,
          label: 'Destination chosen',
          complete: true,
          actionLabel: 'Set destination',
        ),
        TripReadinessItem(
          issue: TripReadinessIssue.stopData,
          label: 'TTC stop list downloaded',
          complete: false,
          actionLabel: 'Download stops',
        ),
      ],
    );

    expect(snapshot.isReady, isFalse);
    expect(snapshot.completeCount, 1);
  });
}
