import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/location_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/trip_ux_copy.dart';
import '../widgets/branded_app_name.dart';

abstract final class LocationPermissionDialogs {
  static Future<void> showDenied(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.location_off_outlined),
          title: const Text('Location permission required'),
          content: BrandedMentionText(
            'DozeAlert needs location access while you use the app to '
            'watch your progress toward your stop.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showBackgroundDenied(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.location_searching),
          title: const Text('Background location required'),
          content: BrandedMentionText(
            'DozeAlert needs background location access to keep watching '
            'your trip when the screen is off or the app is minimized.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await openAppSettings();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showPermanentlyDenied(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.settings_outlined),
          title: const Text('Location permission blocked'),
          content: BrandedMentionText(
            'Location access was permanently denied. Open Settings to '
            'enable location permission for DozeAlert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await openAppSettings();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showBatteryOptimization(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.battery_alert_outlined),
          title: const Text('Battery optimization detected'),
          content: BrandedMentionText(
            'Allow DozeAlert to run without battery restrictions for '
            'reliable alarms.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  static Future<void> showForegroundServiceFailure(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.error_outline),
          title: const Text(TripUxCopy.tripCouldNotStartTitle),
          content: BrandedMentionText(TripUxCopy.tripCouldNotStartBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

abstract final class LocationFeedback {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> handleStartResult(
    BuildContext context,
    LocationStartResult result, {
    BackgroundMonitorService? backgroundMonitorService,
    Future<void> Function()? onContinueAfterBatteryPrompt,
  }) async {
    switch (result) {
      case LocationStartResult.success:
      case LocationStartResult.cancelled:
        return;
      case LocationStartResult.noDestination:
        showSnackBar(context, TripUxCopy.selectDestinationBeforeTrip);
      case LocationStartResult.permissionDenied:
        await LocationPermissionDialogs.showDenied(context);
      case LocationStartResult.permissionPermanentlyDenied:
        await LocationPermissionDialogs.showPermanentlyDenied(context);
      case LocationStartResult.backgroundPermissionDenied:
        await LocationPermissionDialogs.showBackgroundDenied(context);
      case LocationStartResult.locationServiceDisabled:
        showSnackBar(context, TripUxCopy.turnOnGpsToStartTrip);
      case LocationStartResult.foregroundServiceFailure:
        await LocationPermissionDialogs.showForegroundServiceFailure(context);
      case LocationStartResult.batteryOptimizationRequired:
        final openSettings = await LocationPermissionDialogs.showBatteryOptimization(
          context,
        );
        if (!context.mounted) {
          return;
        }
        if (openSettings && backgroundMonitorService != null) {
          await backgroundMonitorService.openBatteryOptimizationSettings();
        } else if (!openSettings) {
          showSnackBar(
            context,
            TripUxCopy.tripMayStopWhenScreenOff,
          );
        }
        if (onContinueAfterBatteryPrompt != null && context.mounted) {
          await onContinueAfterBatteryPrompt();
        }
    }
  }
}

abstract final class LocationFormat {
  static String lastUpdated(DateTime timestamp) {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final seconds = timestamp.second.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
