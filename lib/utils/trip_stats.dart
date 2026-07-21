import '../models/trip_history_entry.dart';

enum TripStatsWindow {
  days30(30, '30 days'),
  days90(90, '90 days'),
  days180(180, '180 days');

  const TripStatsWindow(this.days, this.label);

  final int days;
  final String label;

  static const TripStatsWindow defaultWindow = TripStatsWindow.days30;

  DateTime startOfWindow({DateTime? now}) {
    final reference = (now ?? DateTime.now()).toLocal();
    return reference.subtract(Duration(days: days));
  }
}

/// Read-only aggregates from [TripHistoryEntry] lists. Does not write prefs or
/// touch monitoring / GPS / alarm paths.
class TripStats {
  const TripStats({
    required this.completedCount,
    required this.missedCount,
    required this.alarmsFiredCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.timeSlept,
    required this.topDestinations,
  });

  static const empty = TripStats(
    completedCount: 0,
    missedCount: 0,
    alarmsFiredCount: 0,
    currentStreak: 0,
    bestStreak: 0,
    timeSlept: Duration.zero,
    topDestinations: [],
  );

  /// Ignore absurd durations from bad clocks (corruption / timezone glitches).
  static const maxSleepPerTrip = Duration(hours: 12);

  final int completedCount;
  final int missedCount;
  final int alarmsFiredCount;
  final int currentStreak;
  final int bestStreak;
  final Duration timeSlept;
  final List<TripDestinationCount> topDestinations;

  int get finishedCount => completedCount + missedCount;

  /// Null when there are no finished trips yet.
  double? get successRate {
    if (finishedCount == 0) {
      return null;
    }
    return completedCount / finishedCount;
  }

  bool get hasData => finishedCount > 0 || alarmsFiredCount > 0;

  static List<TripHistoryEntry> entriesInWindow(
    List<TripHistoryEntry> entries,
    TripStatsWindow window, {
    DateTime? now,
  }) {
    final cutoff = window.startOfWindow(now: now);
    return entries
        .where((entry) => !entry.tripStart.isBefore(cutoff))
        .toList(growable: false);
  }

  static TripStats fromEntries(
    List<TripHistoryEntry> entries, {
    TripStatsWindow? window,
    DateTime? now,
  }) {
    final scoped = window == null
        ? entries
        : entriesInWindow(entries, window, now: now);

    var completed = 0;
    var missed = 0;
    var alarms = 0;
    var slept = Duration.zero;
    final destinationCounts = <String, int>{};

    // Newest-first (how history is stored).
    for (final entry in scoped) {
      if (entry.alarmTriggered != null) {
        alarms++;
      }

      if (entry.missedTrip) {
        missed++;
        continue;
      }

      if (entry.tripEnd == null) {
        continue;
      }

      completed++;
      final name = entry.destination.trim();
      if (name.isNotEmpty) {
        destinationCounts[name] = (destinationCounts[name] ?? 0) + 1;
      }

      final sleepEnd = entry.alarmTriggered ?? entry.tripEnd!;
      final sleep = sleepEnd.difference(entry.tripStart);
      if (!sleep.isNegative && sleep <= maxSleepPerTrip) {
        slept += sleep;
      }
    }

    final (current, best) = _streaks(scoped);
    final top = destinationCounts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) {
          return byCount;
        }
        return a.key.compareTo(b.key);
      });

    return TripStats(
      completedCount: completed,
      missedCount: missed,
      alarmsFiredCount: alarms,
      currentStreak: current,
      bestStreak: best,
      timeSlept: slept,
      topDestinations: top
          .take(3)
          .map((e) => TripDestinationCount(name: e.key, count: e.value))
          .toList(growable: false),
    );
  }

  /// Consecutive completed (non-missed, ended) trips from newest; best over all.
  static (int current, int best) _streaks(List<TripHistoryEntry> entries) {
    var current = 0;
    var best = 0;
    var running = 0;
    var currentOpen = true;

    for (final entry in entries) {
      if (entry.tripEnd == null && !entry.missedTrip) {
        continue;
      }
      if (entry.missedTrip) {
        if (currentOpen) {
          currentOpen = false;
        }
        best = running > best ? running : best;
        running = 0;
        continue;
      }
      running++;
      if (currentOpen) {
        current = running;
      }
      best = running > best ? running : best;
    }

    return (current, best);
  }
}

class TripDestinationCount {
  const TripDestinationCount({
    required this.name,
    required this.count,
  });

  final String name;
  final int count;
}

abstract final class TripStatsFormat {
  static String duration(Duration value) {
    if (value.inMinutes < 1) {
      return '0 min';
    }
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return hours == 1 ? '1 hr' : '$hours hr';
    }
    return '${hours}h ${minutes}m';
  }

  static String successRate(double rate) {
    final pct = (rate * 100).round();
    return '$pct%';
  }

  static String teaser(TripStats stats) {
    if (!stats.hasData) {
      return 'No trip stats yet';
    }

    final trips = stats.completedCount == 1
        ? '1 trip'
        : '${stats.completedCount} trips';
    if (stats.timeSlept > Duration.zero) {
      return '$trips · ${duration(stats.timeSlept)} slept';
    }
    return trips;
  }
}
