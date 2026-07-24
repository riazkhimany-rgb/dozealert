import 'dart:io';

import 'package:flutter/material.dart';

import '../services/app_permissions_service.dart';
import '../utils/trip_ux_copy.dart';
import 'branded_app_name.dart';

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
              BrandedMentionText(
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
  final isIos = Platform.isIOS;
  return switch (step) {
    PermissionSetupStep.locationWhenInUse => _StepDialogCopy(
        icon: Icons.location_on_outlined,
        title: TripUxCopy.permissionReasonLocation,
        body: isIos
            ? TripUxCopy.permissionDialogLocationBodyIos
            : TripUxCopy.permissionDialogLocationBody,
        highlight: isIos
            ? TripUxCopy.permissionDialogLocationHighlightIos
            : TripUxCopy.permissionDialogLocationHighlight,
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.backgroundLocation => _StepDialogCopy(
        icon: Icons.my_location,
        title: TripUxCopy.permissionReasonBackground,
        body: isIos
            ? TripUxCopy.permissionDialogBackgroundBodyIos
            : TripUxCopy.permissionDialogBackgroundBody,
        highlight: isIos
            ? TripUxCopy.permissionDialogBackgroundHighlightIos
            : TripUxCopy.permissionDialogBackgroundHighlight,
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.notifications => _StepDialogCopy(
        icon: Icons.notifications_outlined,
        title: TripUxCopy.permissionReasonNotifications,
        body: isIos
            ? TripUxCopy.permissionDialogNotificationsBodyIos
            : TripUxCopy.permissionDialogNotificationsBody,
        highlight: TripUxCopy.permissionDialogNotificationsHighlight,
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.activityRecognition => const _StepDialogCopy(
        icon: Icons.directions_transit_outlined,
        title: TripUxCopy.permissionReasonActivity,
        body: TripUxCopy.permissionDialogActivityBody,
        highlight: TripUxCopy.permissionDialogActivityHighlight,
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.batteryOptimization => const _StepDialogCopy(
        icon: Icons.battery_alert_outlined,
        title: TripUxCopy.permissionReasonBattery,
        body: TripUxCopy.permissionDialogBatteryBody,
        highlight: TripUxCopy.permissionDialogBatteryHighlight,
        actionLabel: 'Continue',
      ),
    PermissionSetupStep.locationServices => null,
  };
}
