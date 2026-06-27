import '../models/transit_mode_snapshot.dart';

abstract final class TransitWakeMessage {
  static String forHome({
    required bool transitModeEnabled,
    required bool gtfsReady,
    required TransitModeSnapshot snapshot,
    required bool isMonitoring,
    String? selectedLine,
    bool gpsSignalLost = false,
  }) {
    if (!transitModeEnabled) {
      return 'Waking by distance to destination';
    }

    if (!gtfsReady) {
      return 'Download your transit stop list to wake by stops';
    }

    if (snapshot.isActive) {
      if (gpsSignalLost) {
        return 'GPS signal weak — showing last known position on $selectedLine';
      }
      if (snapshot.stopsRemaining == 0) {
        return 'At your stop on $selectedLine';
      }
      return 'Waking by stops on $selectedLine';
    }

    if (isMonitoring) {
      return 'Waiting to lock onto your route — $selectedLine';
    }

    return 'Tap Start to begin tracking your ride.';
  }
}
