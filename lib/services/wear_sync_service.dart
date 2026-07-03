import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/monitoring_state.dart';
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/alarm_service.dart';
import '../utils/wear_trip_state_payload.dart';

/// Whether the DozeAlert watch app is installed on a paired watch, and whether
/// that watch is currently reachable.
class WearAppStatus {
  const WearAppStatus({
    required this.appInstalled,
    required this.connected,
  });

  final bool appInstalled;
  final bool connected;
}

/// Syncs trip state to a paired Wear OS companion and receives watch commands.
class WearSyncService {
  WearSyncService({
    required MonitoringProvider monitoringProvider,
    required LocationProvider locationProvider,
    required TransitModeProvider transitModeProvider,
    required GtfsProvider gtfsProvider,
    required SettingsProvider settingsProvider,
    required AlarmService alarmService,
  }) : _monitoringProvider = monitoringProvider,
       _locationProvider = locationProvider,
       _transitModeProvider = transitModeProvider,
       _gtfsProvider = gtfsProvider,
       _settingsProvider = settingsProvider,
       _alarmService = alarmService {
    _monitoringProvider.addListener(_schedulePush);
    _locationProvider.addListener(_schedulePush);
    _transitModeProvider.addListener(_schedulePush);
    _settingsProvider.addListener(_schedulePush);
  }

  static const _channel = MethodChannel('app.dozealert/wear');
  static const _eventChannel = EventChannel('app.dozealert/wear_commands');

  static const cmdStartMonitoring = '/cmd/start_monitoring';
  static const cmdStopMonitoring = '/cmd/stop_monitoring';
  static const cmdDismissAlarm = '/cmd/dismiss_alarm';
  static const cmdOpenPhone = '/cmd/open_phone';

  final MonitoringProvider _monitoringProvider;
  final LocationProvider _locationProvider;
  final TransitModeProvider _transitModeProvider;
  final GtfsProvider _gtfsProvider;
  final SettingsProvider _settingsProvider;
  final AlarmService _alarmService;

  StreamSubscription<dynamic>? _commandSubscription;
  Timer? _pushTimer;
  bool _initialized = false;
  MonitoringState? _lastMonitoringState;

  Future<void> Function()? onStartMonitoring;
  Future<void> Function()? onStopMonitoring;
  Future<void> Function()? onDismissAlarm;

  Future<void> initialize() async {
    if (!Platform.isAndroid || _initialized) {
      return;
    }

    _initialized = true;
    _commandSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is String) {
          unawaited(_handleWearCommand(event));
        }
      },
    );

    final pending = await _channel.invokeMethod<String?>(
      'consumePendingWearCommand',
    );
    if (pending != null) {
      unawaited(_handleWearCommand(pending));
    }

    await pushTripState();
    await _maybeLaunchWearApp(force: true);
  }

  Future<void> dispose() async {
    _pushTimer?.cancel();
    await _commandSubscription?.cancel();
    _monitoringProvider.removeListener(_schedulePush);
    _locationProvider.removeListener(_schedulePush);
    _transitModeProvider.removeListener(_schedulePush);
    _settingsProvider.removeListener(_schedulePush);
    _initialized = false;
  }

  Future<WearAppStatus> refreshWatchConnection() async {
    if (!Platform.isAndroid) {
      return const WearAppStatus(appInstalled: false, connected: false);
    }

    try {
      final status = await _channel.invokeMapMethod<String, dynamic>(
        'wearAppStatus',
      );
      if (status == null) {
        return const WearAppStatus(appInstalled: false, connected: false);
      }
      return WearAppStatus(
        appInstalled: status['installed'] == true,
        connected: status['connected'] == true,
      );
    } on PlatformException {
      return const WearAppStatus(appInstalled: false, connected: false);
    }
  }

  Future<void> pushTripState() async {
    if (!Platform.isAndroid) {
      return;
    }

    await pushTripStateMap(
      WearTripStatePayload.build(
        monitoring: _monitoringProvider,
        location: _locationProvider,
        transitMode: _transitModeProvider,
        gtfs: _gtfsProvider,
        settings: _settingsProvider,
        alarm: _alarmService,
      ),
    );
  }

  Future<void> pushTripStateMap(Map<String, dynamic> payload) async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('pushTripState', payload);
    } on PlatformException {
      // Wear API unavailable on this device/build.
    }

    await _maybeLaunchWearApp();
  }

  Future<void> _maybeLaunchWearApp({bool force = false}) async {
    if (!Platform.isAndroid) {
      return;
    }

    final monitoringState = _monitoringProvider.currentState;
    final shouldLaunch = monitoringState == MonitoringState.monitoring &&
        (force || _lastMonitoringState != MonitoringState.monitoring);
    _lastMonitoringState = monitoringState;

    if (!shouldLaunch) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('launchWearApp');
    } on PlatformException {
      // No paired watch or Wear API unavailable.
    }
  }

  Future<void> _handleWearCommand(String command) async {
    switch (command) {
      case cmdOpenPhone:
        break;
      case cmdStartMonitoring:
        await onStartMonitoring?.call();
      case cmdStopMonitoring:
        await onStopMonitoring?.call();
      case cmdDismissAlarm:
        await onDismissAlarm?.call();
    }
    await pushTripState();
  }

  void _schedulePush() {
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(pushTripState());
    });
  }
}
