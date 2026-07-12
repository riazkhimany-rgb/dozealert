import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/models/trip_history_entry.dart';
import 'package:dozealert/utils/trip_stats.dart';

void main() {
  final base = DateTime(2026, 7, 1, 8);

  TripHistoryEntry completed({
    required String id,
    required String destination,
    required Duration length,
    Duration? untilAlarm,
    bool missed = false,
  }) {
    final start = base.add(Duration(days: int.parse(id)));
    final alarm = untilAlarm == null ? null : start.add(untilAlarm);
    final end = start.add(length);
    return TripHistoryEntry(
      id: id,
      destination: destination,
      tripStart: start,
      tripEnd: end,
      alarmTriggered: alarm,
      alarmDismissed: alarm == null ? null : end,
      missedTrip: missed,
    );
  }

  test('aggregates totals, sleep, streak, and top destinations', () {
    // Newest first, matching TripHistoryService order.
    final entries = [
      completed(
        id: '3',
        destination: 'Union',
        length: const Duration(minutes: 40),
        untilAlarm: const Duration(minutes: 35),
      ),
      completed(
        id: '2',
        destination: 'Union',
        length: const Duration(minutes: 30),
        untilAlarm: const Duration(minutes: 28),
      ),
      completed(
        id: '1',
        destination: 'Oakville',
        length: const Duration(minutes: 50),
        untilAlarm: const Duration(minutes: 45),
      ),
      completed(
        id: '0',
        destination: 'Bloor',
        length: const Duration(minutes: 20),
        missed: true,
      ),
    ];

    final stats = TripStats.fromEntries(entries);

    expect(stats.completedCount, 3);
    expect(stats.missedCount, 1);
    expect(stats.alarmsFiredCount, 3);
    expect(stats.successRate, closeTo(0.75, 0.001));
    expect(stats.currentStreak, 3);
    expect(stats.bestStreak, 3);
    expect(stats.timeSlept, const Duration(minutes: 108));
    expect(stats.topDestinations.first.name, 'Union');
    expect(stats.topDestinations.first.count, 2);
  });

  test('current streak resets after a newer miss', () {
    final entries = [
      completed(
        id: '2',
        destination: 'A',
        length: const Duration(minutes: 10),
        missed: true,
      ),
      completed(
        id: '1',
        destination: 'B',
        length: const Duration(minutes: 10),
      ),
      completed(
        id: '0',
        destination: 'C',
        length: const Duration(minutes: 10),
      ),
    ];

    final stats = TripStats.fromEntries(entries);
    expect(stats.currentStreak, 0);
    expect(stats.bestStreak, 2);
  });

  test('ignores absurd sleep durations', () {
    final start = base;
    final entries = [
      TripHistoryEntry(
        id: '1',
        destination: 'Far',
        tripStart: start,
        tripEnd: start.add(const Duration(days: 2)),
        alarmTriggered: start.add(const Duration(days: 2)),
      ),
    ];

    final stats = TripStats.fromEntries(entries);
    expect(stats.completedCount, 1);
    expect(stats.timeSlept, Duration.zero);
  });

  test('formats teaser and duration', () {
    expect(TripStatsFormat.duration(const Duration(minutes: 45)), '45 min');
    expect(TripStatsFormat.duration(const Duration(hours: 2)), '2 hr');
    expect(
      TripStatsFormat.duration(const Duration(hours: 1, minutes: 5)),
      '1h 5m',
    );
    expect(
      TripStatsFormat.teaser(
        const TripStats(
          completedCount: 12,
          missedCount: 1,
          alarmsFiredCount: 10,
          currentStreak: 5,
          bestStreak: 5,
          timeSlept: Duration(hours: 3),
          topDestinations: [],
        ),
      ),
      '12 trips · 5-trip streak',
    );
  });

  test('filters stats to the selected window', () {
    final now = DateTime(2026, 7, 12, 12);
    final recentStart = now.subtract(const Duration(days: 5));
    final oldStart = now.subtract(const Duration(days: 60));
    final entries = [
      TripHistoryEntry(
        id: 'new',
        destination: 'Recent',
        tripStart: recentStart,
        tripEnd: recentStart.add(const Duration(hours: 1)),
        alarmTriggered: recentStart.add(const Duration(minutes: 50)),
      ),
      TripHistoryEntry(
        id: 'old',
        destination: 'Old',
        tripStart: oldStart,
        tripEnd: oldStart.add(const Duration(hours: 1)),
        alarmTriggered: oldStart.add(const Duration(minutes: 40)),
      ),
    ];

    final last30 = TripStats.fromEntries(
      entries,
      window: TripStatsWindow.days30,
      now: now,
    );
    final last90 = TripStats.fromEntries(
      entries,
      window: TripStatsWindow.days90,
      now: now,
    );

    expect(last30.completedCount, 1);
    expect(last30.topDestinations.single.name, 'Recent');
    expect(last90.completedCount, 2);
  });
}
