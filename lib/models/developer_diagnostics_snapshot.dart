import 'trip_history_entry.dart';

class DeveloperDiagnosticsSnapshot {
  const DeveloperDiagnosticsSnapshot({
    required this.exportedAt,
    required this.currentLocation,
    required this.currentStation,
    required this.nextStation,
    required this.destination,
    required this.stationsRemaining,
    required this.distanceRemainingKm,
    required this.speedKmh,
    required this.monitoringStatus,
    required this.alarmActive,
    required this.foregroundServiceRunning,
    required this.batteryOptimizationDisabled,
    required this.lastGpsUpdate,
    required this.notificationPermissionGranted,
    required this.locationPermissionGranted,
    required this.backgroundLocationPermissionGranted,
    required this.lastAlarmTriggered,
    required this.lastAlarmDismissed,
    required this.gpsEnabled,
    required this.backgroundMonitoringEnabled,
    required this.tripHistory,
  });

  final DateTime exportedAt;
  final String currentLocation;
  final String currentStation;
  final String nextStation;
  final String destination;
  final int stationsRemaining;
  final double distanceRemainingKm;
  final String speedKmh;
  final String monitoringStatus;
  final bool alarmActive;
  final bool foregroundServiceRunning;
  final bool batteryOptimizationDisabled;
  final String lastGpsUpdate;
  final bool notificationPermissionGranted;
  final bool locationPermissionGranted;
  final bool backgroundLocationPermissionGranted;
  final String lastAlarmTriggered;
  final String lastAlarmDismissed;
  final bool gpsEnabled;
  final bool backgroundMonitoringEnabled;
  final List<TripHistoryEntry> tripHistory;

  Map<String, dynamic> toJson() {
    return {
      'exportedAt': exportedAt.toIso8601String(),
      'currentLocation': currentLocation,
      'currentStation': currentStation,
      'nextStation': nextStation,
      'destination': destination,
      'stationsRemaining': stationsRemaining,
      'distanceRemainingKm': distanceRemainingKm,
      'speedKmh': speedKmh,
      'monitoringStatus': monitoringStatus,
      'alarmActive': alarmActive,
      'foregroundServiceRunning': foregroundServiceRunning,
      'batteryOptimizationDisabled': batteryOptimizationDisabled,
      'lastGpsUpdate': lastGpsUpdate,
      'notificationPermissionGranted': notificationPermissionGranted,
      'locationPermissionGranted': locationPermissionGranted,
      'backgroundLocationPermissionGranted':
          backgroundLocationPermissionGranted,
      'lastAlarmTriggered': lastAlarmTriggered,
      'lastAlarmDismissed': lastAlarmDismissed,
      'gpsEnabled': gpsEnabled,
      'backgroundMonitoringEnabled': backgroundMonitoringEnabled,
      'tripHistory': tripHistory.map((entry) => entry.toJson()).toList(),
    };
  }
}
