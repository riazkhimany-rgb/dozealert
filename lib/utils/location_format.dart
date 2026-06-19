import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/location_provider.dart';

abstract final class LocationPermissionDialogs {
  static Future<void> showDenied(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.location_off_outlined),
          title: const Text('Location permission required'),
          content: const Text(
            'DozeAlert needs location access while you use the app to '
            'monitor your progress toward your destination.',
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

  static Future<void> showPermanentlyDenied(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.settings_outlined),
          title: const Text('Location permission blocked'),
          content: const Text(
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
}

abstract final class LocationFeedback {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> handleStartResult(
    BuildContext context,
    LocationStartResult result,
  ) async {
    switch (result) {
      case LocationStartResult.success:
        return;
      case LocationStartResult.noDestination:
        showSnackBar(context, 'Select a destination before monitoring.');
      case LocationStartResult.permissionDenied:
        await LocationPermissionDialogs.showDenied(context);
      case LocationStartResult.permissionPermanentlyDenied:
        await LocationPermissionDialogs.showPermanentlyDenied(context);
      case LocationStartResult.locationServiceDisabled:
        showSnackBar(context, 'Turn on GPS to start location monitoring.');
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
