import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/developer_diagnostics_snapshot.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/alarm_service.dart';
import '../services/background_monitor_service.dart';
import '../services/location_service.dart';
import '../services/trip_history_service.dart';
import '../utils/app_log.dart';
import '../utils/location_format.dart';
import '../utils/monitoring_format.dart';

class DeveloperDiagnosticsService {
  DeveloperDiagnosticsService(
    this._locationService,
    this._backgroundMonitorService,
    this._alarmService,
    this._tripHistoryService,
  );

  final LocationService _locationService;
  final BackgroundMonitorService _backgroundMonitorService;
  final AlarmService _alarmService;
  final TripHistoryService _tripHistoryService;

  Future<DeveloperDiagnosticsSnapshot> collectSnapshot({
    required LocationProvider locationProvider,
    required MonitoringProvider monitoringProvider,
    required TransitModeProvider transitModeProvider,
  }) async {
    final location = locationProvider.currentLocation;
    final snapshot = transitModeProvider.snapshot;
    final destination = monitoringProvider.selectedDestination;
    final diagnostics = locationProvider.backgroundDiagnostics;

    final locationPermission = await _permissionGranted(Permission.locationWhenInUse);
    final backgroundPermission = await _permissionGranted(Permission.locationAlways);
    final notificationPermission = await _permissionGranted(Permission.notification);
    final gpsEnabled = await _safeFuture(
      _locationService.isLocationServiceEnabled(),
      fallback: false,
    );
    final batteryOptimizationEnabled = await _safeFuture(
      _backgroundMonitorService.isBatteryOptimizationEnabled(),
      fallback: false,
    );
    final tripHistory = await _tripHistoryService.loadHistory();

    return DeveloperDiagnosticsSnapshot(
      exportedAt: DateTime.now(),
      currentLocation: location == null
          ? '—'
          : '${location.latitude.toStringAsFixed(5)}, '
              '${location.longitude.toStringAsFixed(5)}',
      currentStation: snapshot.currentStop?.stopName ?? '—',
      nextStation: snapshot.nextStop?.stopName ?? '—',
      destination: destination?.name ?? '—',
      stationsRemaining: snapshot.stopsRemaining,
      distanceRemainingKm: locationProvider.distanceRemainingKm,
      speedKmh: location == null
          ? '—'
          : '${location.speedKmh.toStringAsFixed(1)} km/h',
      monitoringStatus: MonitoringFormat.stateLabel(
        monitoringProvider.currentState,
      ),
      alarmActive: _alarmService.alarmActive,
      foregroundServiceRunning: diagnostics.foregroundServiceRunning,
      batteryOptimizationDisabled: !batteryOptimizationEnabled,
      lastGpsUpdate: location?.timestamp == null
          ? '—'
          : LocationFormat.lastUpdated(location!.timestamp),
      notificationPermissionGranted: notificationPermission,
      locationPermissionGranted: locationPermission,
      backgroundLocationPermissionGranted: backgroundPermission,
      lastAlarmTriggered: _formatTimestamp(_alarmService.lastAlarmTriggeredAt),
      lastAlarmDismissed: _formatTimestamp(_alarmService.lastAlarmDismissedAt),
      gpsEnabled: gpsEnabled,
      backgroundMonitoringEnabled: diagnostics.backgroundMonitoringEnabled,
      tripHistory: tripHistory,
    );
  }

  Future<File> exportDiagnosticsJson({
    required DeveloperDiagnosticsSnapshot snapshot,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/diagnostics.json');
    final payload = {
      ...snapshot.toJson(),
      'diagnostics': {
        'gpsEnabled': snapshot.gpsEnabled,
        'locationPermissionGranted': snapshot.locationPermissionGranted,
        'backgroundLocationPermissionGranted':
            snapshot.backgroundLocationPermissionGranted,
        'notificationPermissionGranted':
            snapshot.notificationPermissionGranted,
        'foregroundServiceRunning': snapshot.foregroundServiceRunning,
        'backgroundMonitoringEnabled': snapshot.backgroundMonitoringEnabled,
        'batteryOptimizationDisabled': snapshot.batteryOptimizationDisabled,
      },
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    AppLog.d('DeveloperDiagnosticsService: exported ${file.path}');
    return file;
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return '—';
    }
    return LocationFormat.lastUpdated(timestamp);
  }

  Future<bool> _permissionGranted(Permission permission) async {
    try {
      return (await permission.status).isGranted;
    } catch (error) {
      AppLog.d('DeveloperDiagnosticsService: permission check failed: $error');
      return false;
    }
  }

  Future<T> _safeFuture<T>(Future<T> future, {required T fallback}) async {
    try {
      return await future;
    } catch (error) {
      AppLog.d('DeveloperDiagnosticsService: async check failed: $error');
      return fallback;
    }
  }
}
