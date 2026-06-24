import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/alarm_service.dart';

/// Syncs trip state to a paired Wear OS companion and receives watch commands.
class WearSyncService {
  WearSyncService({
    required MonitoringProvider monitoringProvider,
    required LocationProvider locationProvider,
    required TransitModeProvider transitModeProvider,
    required GtfsProvider gtfsProvider,
    required AlarmService alarmService,
  }) : _monitoringProvider = monitoringProvider,
       _locationProvider = locationProvider,
       _transitModeProvider = transitModeProvider,
       _gtfsProvider = gtfsProvider,
       _alarmService = alarmService {
    _monitoringProvider.addListener(_schedulePush);
    _locationProvider.addListener(_schedulePush);
    _transitModeProvider.addListener(_schedulePush);
  }

  static const _channel = MethodChannel('app.dozealert/wear');
  static const _eventChannel = EventChannel('app.dozealert/wear_commands');

  static const cmdStartMonitoring = '/cmd/start_monitoring';
  static const cmdStopMonitoring = '/cmd/stop_monitoring';
  static const cmdDismissAlarm = '/cmd/dismiss_alarm';

  final MonitoringProvider _monitoringProvider;
  final LocationProvider _locationProvider;
  final TransitModeProvider _transitModeProvider;
  final GtfsProvider _gtfsProvider;
  final AlarmService _alarmService;

  StreamSubscription<dynamic>? _commandSubscription;
  Timer? _pushTimer;
  bool _initialized = false;

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
  }

  Future<void> dispose() async {
    _pushTimer?.cancel();
    await _commandSubscription?.cancel();
    _monitoringProvider.removeListener(_schedulePush);
    _locationProvider.removeListener(_schedulePush);
    _transitModeProvider.removeListener(_schedulePush);
    _initialized = false;
  }

  Future<void> pushTripState() async {
    if (!Platform.isAndroid) {
      return;
    }

    final monitoring = _monitoringProvider;
    final destination = monitoring.selectedDestination;
    final transit = _transitModeProvider.snapshot;
    final alarmActive =
        _alarmService.alarmActive || _locationProvider.arrivalDialogVisible;

    final payload = <String, dynamic>{
      'state': monitoring.currentState.name,
      'destinationName': destination?.name ?? '',
      'distanceKm': _locationProvider.distanceRemainingKm,
      'distanceReady': _locationProvider.distanceIsReady,
      'stopsRemaining': transit.isActive ? transit.stopsRemaining : -1,
      'transitActive': transit.isActive,
      'lineLabel': _gtfsProvider.selectedLineLabel,
      'alarmActive': alarmActive,
      'hasDestination': destination != null,
    };

    try {
      await _channel.invokeMethod<void>('pushTripState', payload);
    } on PlatformException {
      // Wear API unavailable on this device/build.
    }
  }

  Future<void> _handleWearCommand(String command) async {
    switch (command) {
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
