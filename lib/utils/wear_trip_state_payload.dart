import '../models/monitoring_state.dart';
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/alarm_service.dart';
import '../utils/gtfs_stop_name_utils.dart';

/// Shared trip-state map for phone → Wear OS sync.
abstract final class WearTripStatePayload {
  static Map<String, dynamic> build({
    required MonitoringProvider monitoring,
    required LocationProvider location,
    required TransitModeProvider transitMode,
    required GtfsProvider gtfs,
    required SettingsProvider settings,
    required AlarmService alarm,
  }) {
    final destination = monitoring.selectedDestination;
    final transitModeEnabled = settings.transitModeEnabled;
    final display = transitMode.displaySnapshot;
    final transit = display.isActive ? display : transitMode.snapshot;
    final alarmActive = alarm.alarmActive || location.arrivalDialogVisible;
    final arrivalContext = location.arrivalContext;

    final nextStop = transit.nextStop;
    final nextStopName = transit.isActive && nextStop != null
        ? GtfsStopNameUtils.stationDisplayName(nextStop.stopName)
        : '';

    return {
      'state': monitoring.currentState.name,
      'destinationName': destination?.name ?? '',
      'distanceKm': location.distanceRemainingKm,
      'distanceReady': location.distanceIsReady,
      'stopsRemaining': transitModeEnabled && transit.isActive
          ? transit.stopsRemaining
          : -1,
      'transitActive': transitModeEnabled && transit.isActive,
      'lineLabel': transitModeEnabled ? gtfs.selectedLineLabel : '',
      'tripConcern': transit.tripConcern ?? '',
      'gpsStale': display.gpsStale,
      'directionLabel': transit.directionLabel ?? '',
      'nextStopName': nextStopName,
      'alarmActive': alarmActive,
      'hasDestination': destination != null,
      'alarmStopName': alarmActive
          ? (arrivalContext?.destinationName ?? destination?.name ?? '')
          : '',
      'alarmHeadline': alarmActive
          ? (arrivalContext?.headline ?? 'Wake up!')
          : '',
      'alarmSubline': alarmActive
          ? (arrivalContext?.wearSubline ?? arrivalContext?.secondaryLine ?? '')
          : '',
    };
  }

  static Map<String, dynamic> fromBackgroundMap(Map<String, Object> source) {
    return {
      'state': source['state']?.toString() ?? MonitoringState.monitoring.name,
      'destinationName': source['destinationName']?.toString() ?? '',
      'distanceKm': _asDouble(source['distanceKm']),
      'distanceReady': source['distanceReady'] == true,
      'stopsRemaining': _asInt(source['stopsRemaining'], fallback: -1),
      'transitActive': source['transitActive'] == true,
      'lineLabel': source['lineLabel']?.toString() ?? '',
      'tripConcern': source['tripConcern']?.toString() ?? '',
      'gpsStale': source['gpsStale'] == true,
      'directionLabel': source['directionLabel']?.toString() ?? '',
      'nextStopName': source['nextStopName']?.toString() ?? '',
      'alarmActive': source['alarmActive'] == true,
      'hasDestination': source['hasDestination'] != false,
      'alarmStopName': source['alarmStopName']?.toString() ?? '',
      'alarmHeadline': source['alarmHeadline']?.toString() ?? '',
      'alarmSubline': source['alarmSubline']?.toString() ?? '',
    };
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }
}
