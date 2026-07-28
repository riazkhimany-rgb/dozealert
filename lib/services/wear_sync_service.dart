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

/// Syncs trip state to a paired Wear OS / Apple Watch companion and receives
/// watch commands. Android uses Play Services Wearable; iOS uses WatchConnectivity.
class WearSyncService {
  WearSyncService({
    required this._monitoringProvider,
    required this._locationProvider,
    required this._transitModeProvider,
    required this._gtfsProvider,
    required this._settingsProvider,
    required this._alarmService,
  }) {
    _monitoringProvider.addListener(_schedulePush);
    _locationProvider.addListener(_schedulePush);
    _transitModeProvider.addListener(_schedulePush);
    _settingsProvider.addListener(_schedulePush);
  }

  static const _androidChannel = MethodChannel('app.dozealert/wear');
  static const _androidEventChannel = EventChannel('app.dozealert/wear_commands');
  static const _androidConnectionChannel =
      EventChannel('app.dozealert/wear_connection');

  static const _iosChannel = MethodChannel('app.dozealert/watch');
  static const _iosEventChannel = EventChannel('app.dozealert/watch_commands');
  static const _iosConnectionChannel =
      EventChannel('app.dozealert/watch_connection');

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

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  MethodChannel get _channel =>
      Platform.isIOS ? _iosChannel : _androidChannel;

  EventChannel get _eventChannel =>
      Platform.isIOS ? _iosEventChannel : _androidEventChannel;

  EventChannel get connectionEventChannel =>
      Platform.isIOS ? _iosConnectionChannel : _androidConnectionChannel;

  String get _consumePendingMethod =>
      Platform.isIOS ? 'consumePendingWatchCommand' : 'consumePendingWearCommand';

  String get _statusMethod =>
      Platform.isIOS ? 'watchAppStatus' : 'wearAppStatus';

  String get _launchMethod =>
      Platform.isIOS ? 'launchWatchApp' : 'launchWearApp';

  Future<void> initialize() async {
    if (!_isSupported || _initialized) {
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

    final pending = await _channel.invokeMethod<String?>(_consumePendingMethod);
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
    if (!_isSupported) {
      return const WearAppStatus(appInstalled: false, connected: false);
    }

    try {
      final status = await _channel.invokeMapMethod<String, dynamic>(
        _statusMethod,
      );
      if (status == null) {
        return const WearAppStatus(appInstalled: false, connected: false);
      }
      return WearAppStatus(
        appInstalled: status['installed'] == true,
        connected: status['installed'] == true && status['connected'] == true,
      );
    } on PlatformException {
      return const WearAppStatus(appInstalled: false, connected: false);
    }
  }

  Future<void> pushTripState() async {
    if (!_isSupported) {
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
    if (!_isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('pushTripState', payload);
    } on PlatformException {
      // Companion API unavailable on this device/build.
    }

    await _maybeLaunchWearApp();
  }

  Future<void> _maybeLaunchWearApp({bool force = false}) async {
    if (!_isSupported) {
      return;
    }

    if (!_settingsProvider.openWatchAppWhenTripStarts) {
      _lastMonitoringState = _monitoringProvider.currentState;
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
      await _channel.invokeMethod<void>(_launchMethod);
    } on PlatformException {
      // No paired watch or companion API unavailable.
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
