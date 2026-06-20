import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/current_location.dart';
import 'background_location_task_handler.dart';
import 'monitoring_storage_service.dart';
import '../utils/app_log.dart';

enum BackgroundMonitorStartResult {
  success,
  unsupportedPlatform,
  notificationPermissionDenied,
  foregroundServiceFailure,
}

class BackgroundMonitorDiagnostics {
  const BackgroundMonitorDiagnostics({
    required this.backgroundMonitoringEnabled,
    required this.foregroundServiceRunning,
  });

  final bool backgroundMonitoringEnabled;
  final bool foregroundServiceRunning;
}

class BackgroundMonitorService {
  BackgroundMonitorService(this._monitoringStorage);

  static const _serviceId = 512;

  final MonitoringStorageService _monitoringStorage;

  final StreamController<CurrentLocation> _locationController =
      StreamController<CurrentLocation>.broadcast();
  final StreamController<void> _arrivalController =
      StreamController<void>.broadcast();

  bool _initialized = false;
  bool _foregroundServiceRunning = false;
  bool _backgroundMonitoringEnabled = false;

  Stream<CurrentLocation> get locationStream => _locationController.stream;

  Stream<void> get arrivalStream => _arrivalController.stream;

  bool get isForegroundServiceRunning => _foregroundServiceRunning;

  bool get isBackgroundMonitoringEnabled => _backgroundMonitoringEnabled;

  BackgroundMonitorDiagnostics get diagnostics {
    return BackgroundMonitorDiagnostics(
      backgroundMonitoringEnabled: _backgroundMonitoringEnabled,
      foregroundServiceRunning: _foregroundServiceRunning,
    );
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_handleTaskData);

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'dozealert_monitoring',
        channelName: 'Trip Monitoring',
        channelDescription:
            'Shown while DozeAlert monitors your trip in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        showWhen: true,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _backgroundMonitoringEnabled = await _monitoringStorage.isMonitoringActive();
    await syncServiceState();
    _initialized = true;
  }

  Future<void> dispose() async {
    FlutterForegroundTask.removeTaskDataCallback(_handleTaskData);
    await _locationController.close();
    await _arrivalController.close();
  }

  Future<void> syncServiceState() async {
    if (!Platform.isAndroid) {
      _foregroundServiceRunning = false;
      return;
    }

    try {
      _foregroundServiceRunning = await FlutterForegroundTask.isRunningService;
      _backgroundMonitoringEnabled = await _monitoringStorage.isMonitoringActive();
    } catch (error, stackTrace) {
      AppLog.d('BackgroundMonitorService: sync failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<bool> isBatteryOptimizationEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      return !(await FlutterForegroundTask.isIgnoringBatteryOptimizations);
    } catch (_) {
      return false;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  Future<bool> ensureNotificationPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission == NotificationPermission.granted) {
      return true;
    }

    final requested = await FlutterForegroundTask.requestNotificationPermission();
    return requested == NotificationPermission.granted;
  }

  Future<BackgroundMonitorStartResult> startMonitoring({
    required String destinationName,
  }) async {
    if (!Platform.isAndroid) {
      return BackgroundMonitorStartResult.unsupportedPlatform;
    }

    if (!await ensureNotificationPermission()) {
      return BackgroundMonitorStartResult.notificationPermissionDenied;
    }

    _backgroundMonitoringEnabled = true;

    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask('refresh_session');
      _foregroundServiceRunning = true;
      return BackgroundMonitorStartResult.success;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: 'DozeAlert',
      notificationText:
          'Monitoring your trip...\n$destinationName · Waiting for location...',
      callback: startBackgroundMonitoringCallback,
    );

    switch (result) {
      case ServiceRequestSuccess():
        _foregroundServiceRunning = true;
        FlutterForegroundTask.sendDataToTask('refresh_session');
        return BackgroundMonitorStartResult.success;
      case ServiceRequestFailure(:final error):
        AppLog.d('BackgroundMonitorService: start failed: $error');
        _foregroundServiceRunning = false;
        _backgroundMonitoringEnabled = false;
        return BackgroundMonitorStartResult.foregroundServiceFailure;
    }
  }

  Future<void> stopMonitoring() async {
    _backgroundMonitoringEnabled = false;
    _foregroundServiceRunning = false;

    if (!Platform.isAndroid) {
      return;
    }

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (error, stackTrace) {
      AppLog.d('BackgroundMonitorService: stop failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> updateNotification({
    required String destinationName,
    required double distanceKm,
  }) async {
    if (!Platform.isAndroid || !_foregroundServiceRunning) {
      return;
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: 'DozeAlert',
      notificationText:
          'Monitoring your trip...\n$destinationName · '
          '${distanceKm.toStringAsFixed(1)} km remaining',
    );
  }

  void _handleTaskData(Object data) {
    if (data is! Map) {
      return;
    }

    final type = data['type'];
    if (type == 'location') {
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      final speed = data['speed'];
      final accuracy = data['accuracy'];
      final timestamp = data['timestamp'];

      if (latitude is! num ||
          longitude is! num ||
          speed is! num ||
          accuracy is! num ||
          timestamp is! int) {
        return;
      }

      _locationController.add(
        CurrentLocation(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
          speed: speed.toDouble(),
          accuracy: accuracy.toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        ),
      );
      return;
    }

    if (type == 'arrived') {
      _arrivalController.add(null);
    }
  }
}
