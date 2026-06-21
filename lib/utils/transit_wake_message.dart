import '../models/transit_mode_snapshot.dart';

abstract final class TransitWakeMessage {
  static String forHome({
    required bool transitModeEnabled,
    required bool gtfsReady,
    required TransitModeSnapshot snapshot,
    required bool isMonitoring,
    String? selectedLine,
  }) {
    if (!transitModeEnabled) {
      return 'Waking by distance to destination';
    }

    if (!gtfsReady) {
      return 'Transit mode on — download GTFS to track stops';
    }

    if (snapshot.isActive) {
      if (snapshot.stopsRemaining == 0) {
        return 'At destination stop on $selectedLine';
      }
      return 'Waking by stops on $selectedLine';
    }

    if (isMonitoring) {
      return 'Waiting for GPS on your line — $selectedLine';
    }

    return 'Start monitoring to match your line — $selectedLine';
  }
}
