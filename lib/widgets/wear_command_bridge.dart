import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/alarm_service.dart';
import '../services/background_monitor_service.dart';
import '../services/wear_sync_service.dart';
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

class _WearCommandBridgeState extends State<WearCommandBridge> {
  WearSyncService? _wearSyncService;

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeWearSync());
    });
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
      alarmService: context.read<AlarmService>(),
    );

    wearSyncService.onStartMonitoring = () => _handleStartMonitoring();
    wearSyncService.onStopMonitoring = () =>
        context.read<LocationProvider>().stopTracking();
    wearSyncService.onDismissAlarm = () => _handleDismissAlarm();

    await wearSyncService.initialize();
    if (!mounted) {
      await wearSyncService.dispose();
      return;
    }

    setState(() => _wearSyncService = wearSyncService);
  }

  Future<void> _handleStartMonitoring() async {
    if (!mounted) {
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    final backgroundMonitorService = context.read<BackgroundMonitorService>();

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
    }

    await tryStart();
    await _wearSyncService?.pushTripState();
  }

  Future<void> _handleDismissAlarm() async {
    if (!mounted) {
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.arrivalDialogVisible) {
      await locationProvider.dismissArrival();
    } else {
      await context.read<AlarmService>().stopAlarm();
      if (locationProvider.trackingEnabled) {
        await locationProvider.stopTracking();
      }
    }

    await _wearSyncService?.pushTripState();
  }

  @override
  void dispose() {
    unawaited(_wearSyncService?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
