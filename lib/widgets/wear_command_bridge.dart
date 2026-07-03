import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../providers/wear_status_provider.dart';
import '../models/monitoring_state.dart';
import '../services/alarm_service.dart';
import '../services/background_monitor_service.dart';
import '../services/wear_sync_service.dart';
import '../utils/wear_trip_state_payload.dart';
import '../utils/location_format.dart';

/// Bridges Wear OS commands to phone-side monitoring actions.
class WearCommandBridge extends StatefulWidget {
  const WearCommandBridge({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<WearCommandBridge> createState() => _WearCommandBridgeState();
}

class _WearCommandBridgeState extends State<WearCommandBridge>
    with WidgetsBindingObserver {
  WearSyncService? _wearSyncService;
  Timer? _wearConnectionTimer;
  StreamSubscription<Map<String, Object>>? _wearSyncSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!Platform.isAndroid) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeWearSync());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshWearConnection());
    }
  }

  Future<void> _initializeWearSync() async {
    if (!mounted || _wearSyncService != null) {
      return;
    }

    final wearSyncService = WearSyncService(
      monitoringProvider: context.read<MonitoringProvider>(),
      locationProvider: context.read<LocationProvider>(),
      transitModeProvider: context.read<TransitModeProvider>(),
      gtfsProvider: context.read<GtfsProvider>(),
      settingsProvider: context.read<SettingsProvider>(),
      alarmService: context.read<AlarmService>(),
    );

    wearSyncService.onStartMonitoring = () => _handleStartMonitoring();
    wearSyncService.onStopMonitoring = () =>
        context.read<LocationProvider>().stopTracking();
    wearSyncService.onDismissAlarm = () => _handleDismissAlarm();

    await wearSyncService.initialize();
    await _refreshWearConnection(wearSyncService);
    _wearConnectionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshWearConnection()),
    );

    if (!mounted) {
      await wearSyncService.dispose();
      return;
    }

    setState(() => _wearSyncService = wearSyncService);

    final backgroundMonitorService = context.read<BackgroundMonitorService>();
    _wearSyncSubscription = backgroundMonitorService.wearSyncStream.listen(
      (payload) => unawaited(
        wearSyncService.pushTripStateMap(
          WearTripStatePayload.fromBackgroundMap(payload),
        ),
      ),
    );
  }

  Future<void> _refreshWearConnection([WearSyncService? service]) async {
    final wearSync = service ?? _wearSyncService;
    if (wearSync == null || !mounted) {
      return;
    }

    final status = await wearSync.refreshWatchConnection();
    if (mounted) {
      context.read<WearStatusProvider>().setWearStatus(
            appInstalled: status.appInstalled,
            connected: status.connected,
          );
    }
  }

  Future<void> _handleStartMonitoring() async {
    if (!mounted) {
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    final backgroundMonitorService = context.read<BackgroundMonitorService>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    Future<void> tryStart({bool resume = false}) async {
      final result = await locationProvider.startTracking(resume: resume);
      if (!mounted) {
        return;
      }

      await LocationFeedback.handleStartResult(
        context,
        result,
        backgroundMonitorService: backgroundMonitorService,
        onContinueAfterBatteryPrompt: result ==
                LocationStartResult.batteryOptimizationRequired
            ? () => tryStart(resume: true)
            : null,
      );

      if (result == LocationStartResult.success) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Monitoring started from your watch'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    await tryStart();
    await _wearSyncService?.pushTripState();
  }

  Future<void> _handleDismissAlarm() async {
    if (!mounted) {
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    final alarmService = context.read<AlarmService>();
    final monitoringState = context.read<MonitoringProvider>().currentState;
    final shouldDismissArrival = locationProvider.arrivalDialogVisible ||
        alarmService.alarmActive ||
        monitoringState == MonitoringState.arrived;

    if (shouldDismissArrival) {
      await locationProvider.dismissArrival();
    } else {
      await alarmService.stopAlarm();
      if (locationProvider.trackingEnabled) {
        await locationProvider.stopTracking();
      }
    }

    await _wearSyncService?.pushTripState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wearConnectionTimer?.cancel();
    unawaited(_wearSyncSubscription?.cancel());
    unawaited(_wearSyncService?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
