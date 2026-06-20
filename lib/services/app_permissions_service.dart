import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../models/app_permission_snapshot.dart';
import 'background_monitor_service.dart';
import 'location_service.dart';

class AppPermissionsService {
  AppPermissionsService(
    this._locationService,
    this._backgroundMonitorService,
  );

  final LocationService _locationService;
  final BackgroundMonitorService _backgroundMonitorService;

  Future<AppPermissionSnapshot> snapshot() async {
    final locationWhenInUseGranted = await ph.Permission.locationWhenInUse.isGranted;
    final backgroundLocationGranted = Platform.isAndroid
        ? await ph.Permission.locationAlways.isGranted
        : locationWhenInUseGranted;
    final notificationsGranted = Platform.isAndroid
        ? await _backgroundMonitorService.ensureNotificationPermission(
            requestIfMissing: false,
          )
        : await ph.Permission.notification.isGranted;
    final locationServicesEnabled =
        await _locationService.isLocationServiceEnabled();
    final batteryOptimizationEnabled = Platform.isAndroid
        ? await _backgroundMonitorService.isBatteryOptimizationEnabled()
        : false;

    return AppPermissionSnapshot(
      locationWhenInUseGranted: locationWhenInUseGranted,
      backgroundLocationGranted: backgroundLocationGranted,
      notificationsGranted: notificationsGranted,
      locationServicesEnabled: locationServicesEnabled,
      batteryOptimizationEnabled: batteryOptimizationEnabled,
    );
  }

  Future<void> requestLocationWhenInUse() async {
    await _locationService.requestPermission();
  }

  Future<void> requestBackgroundLocation() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _locationService.requestBackgroundPermission();
  }

  Future<bool> requestNotifications() async {
    if (!Platform.isAndroid) {
      final status = await ph.Permission.notification.request();
      return status.isGranted;
    }

    return _backgroundMonitorService.ensureNotificationPermission(
      requestIfMissing: true,
    );
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettingsPage() async {
    await ph.openAppSettings();
  }

  Future<void> openBatterySettings() async {
    await _backgroundMonitorService.openBatteryOptimizationSettings();
  }
}
