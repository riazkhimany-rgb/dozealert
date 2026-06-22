import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../models/app_permission_snapshot.dart';
import 'background_monitor_service.dart';
import 'location_service.dart';

enum PermissionSetupStep {
  locationServices,
  locationWhenInUse,
  backgroundLocation,
  notifications,
  batteryOptimization,
}

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
    await requestBatteryOptimization();
  }

  Future<void> requestBatteryOptimization() async {
    if (!Platform.isAndroid) {
      return;
    }

    await _backgroundMonitorService.openBatteryOptimizationSettings();
  }

  /// Requests missing **required** permissions in Android's required order,
  /// then prompts for battery optimization exemption.
  /// Opens system settings when a runtime dialog cannot be shown (GPS off).
  Future<AppPermissionSnapshot> runAutomaticSetupFlow({
    void Function(PermissionSetupStep step)? onStep,
    Future<bool> Function(PermissionSetupStep step)? onBeforeStep,
  }) async {
    var snapshot = await this.snapshot();

    Future<bool> proceed(PermissionSetupStep step) async {
      onStep?.call(step);
      final confirm = onBeforeStep;
      if (confirm == null) {
        return true;
      }
      return confirm(step);
    }

    if (!snapshot.locationServicesEnabled) {
      if (!await proceed(PermissionSetupStep.locationServices)) {
        return snapshot;
      }
      await openLocationSettings();
      return this.snapshot();
    }

    if (!snapshot.locationWhenInUseGranted) {
      if (!await proceed(PermissionSetupStep.locationWhenInUse)) {
        return snapshot;
      }
      final whenInUse = await ph.Permission.locationWhenInUse.status;
      if (whenInUse.isPermanentlyDenied) {
        await openAppSettingsPage();
        return this.snapshot();
      }

      await requestLocationWhenInUse();
      snapshot = await this.snapshot();
      if (!snapshot.locationWhenInUseGranted) {
        return snapshot;
      }
    }

    if (Platform.isAndroid && !snapshot.backgroundLocationGranted) {
      if (!await proceed(PermissionSetupStep.backgroundLocation)) {
        return snapshot;
      }
      final background = await ph.Permission.locationAlways.status;
      if (background.isPermanentlyDenied) {
        await openAppSettingsPage();
        return this.snapshot();
      }

      await requestBackgroundLocation();
      snapshot = await this.snapshot();
      if (!snapshot.backgroundLocationGranted) {
        await openAppSettingsPage();
        snapshot = await this.snapshot();
        if (!snapshot.backgroundLocationGranted) {
          return snapshot;
        }
      }
    }

    if (Platform.isAndroid && !snapshot.notificationsGranted) {
      if (!await proceed(PermissionSetupStep.notifications)) {
        return snapshot;
      }
      final notifications = await ph.Permission.notification.status;
      if (notifications.isPermanentlyDenied) {
        await openAppSettingsPage();
        return this.snapshot();
      }

      await requestNotifications();
      snapshot = await this.snapshot();
    }

    if (Platform.isAndroid && snapshot.batteryOptimizationEnabled) {
      if (!await proceed(PermissionSetupStep.batteryOptimization)) {
        return snapshot;
      }
      await requestBatteryOptimization();
      snapshot = await this.snapshot();
    }

    return snapshot;
  }
}
