import 'dart:io';

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
    if (Platform.isIOS) {
      return _showIosAlwaysSettingsGuide(context);
    }

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

  /// Opens DozeAlert's own Settings page (not a generic Apps list).
  /// Apple does not allow apps to set Always location programmatically.
  static Future<void> _showIosAlwaysSettingsGuide(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: const Icon(Icons.my_location),
          title: const Text(TripUxCopy.iosAlwaysSettingsTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandedMentionText(
                  TripUxCopy.iosAlwaysSettingsBody,
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                _IosAlwaysStepRow(
                  number: '1',
                  label: TripUxCopy.iosAlwaysSettingsStep1,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),
                _IosAlwaysStepRow(
                  number: '2',
                  label: TripUxCopy.iosAlwaysSettingsStep2,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await openAppSettings();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text(TripUxCopy.iosAlwaysSettingsOpenButton),
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
            Platform.isIOS
                ? 'Location was turned off for DozeAlert. Tap Open Settings '
                    '(opens DozeAlert directly), then Location → Always.'
                : 'Location access was permanently denied. Open Settings to '
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
              child: const Text(TripUxCopy.iosAlwaysSettingsOpenButton),
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

class _IosAlwaysStepRow extends StatelessWidget {
  const _IosAlwaysStepRow({
    required this.number,
    required this.label,
    required this.colorScheme,
  });

  final String number;
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
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
