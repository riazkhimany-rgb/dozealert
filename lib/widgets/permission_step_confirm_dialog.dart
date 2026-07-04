import 'package:flutter/material.dart';

import '../services/app_permissions_service.dart';

/// Blocks the auto permission flow until the user acknowledges what to tap
/// on the next system screen.
Future<bool> showPermissionStepConfirmDialog(
  BuildContext context,
  PermissionSetupStep step,
) async {
  final data = _copyForStep(step);
  if (data == null) {
    return true;
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        icon: Icon(data.icon),
        title: Text(data.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.body,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
              ),
              if (data.highlight != null) ...[
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      data.highlight!,
                      style: Theme.of(dialogContext)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(dialogContext)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(data.actionLabel),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

class _StepDialogCopy {
  const _StepDialogCopy({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    this.highlight,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final String? highlight;
}

_StepDialogCopy? _copyForStep(PermissionSetupStep step) {
  return switch (step) {
    PermissionSetupStep.locationWhenInUse => const _StepDialogCopy(
        icon: Icons.location_on_outlined,
        title: 'Know which stop you\'re passing',
        body:
            'Android asks for location in two steps. This is step 1 — '
            'so DozeAlert can see your position while the app is open.',
        highlight: 'Tap "While using the app"',
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.backgroundLocation => const _StepDialogCopy(
        icon: Icons.my_location,
        title: 'Keep watching while your screen is off',
        body:
            'DozeAlert needs background location so monitoring continues '
            'when you lock your phone or switch apps.\n\n'
            'The next screen may be an Android dialog or app settings.',
        highlight: 'Choose "Allow all the time"',
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.notifications => const _StepDialogCopy(
        icon: Icons.notifications_outlined,
        title: 'Wake you with sound and vibration',
        body:
            'DozeAlert shows a small ongoing notification while watching '
            'your trip, and uses alerts to wake you before your stop.',
        highlight: 'Tap "Allow"',
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.activityRecognition => const _StepDialogCopy(
        icon: Icons.directions_transit_outlined,
        title: 'On the train vs at the platform',
        body:
            'Physical activity helps DozeAlert tell when you are riding '
            'versus waiting at a station — so wake timing stays accurate.',
        highlight: 'Tap "Allow"',
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.batteryOptimization => const _StepDialogCopy(
        icon: Icons.battery_alert_outlined,
        title: 'So Android doesn\'t stop the trip',
        body:
            'Some phones limit background apps. Allowing battery exemption '
            'helps your alarm stay reliable while you sleep.',
        highlight: 'Tap "Allow" or "Unrestricted"',
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.locationServices => null,
  };
}
