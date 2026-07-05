import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_permission_snapshot.dart';
import '../services/app_permissions_service.dart';
import '../utils/trip_ux_copy.dart';

class PermissionReasonSummary {
  const PermissionReasonSummary({
    required this.label,
    required this.reason,
  });

  final String label;
  final String reason;
}

List<PermissionReasonSummary> permissionReasonSummaries({
  bool includeActivityRecognition = true,
}) {
  if (!Platform.isAndroid) {
    return const [
      PermissionReasonSummary(
        label: 'Location',
        reason: TripUxCopy.permissionReasonLocation,
      ),
    ];
  }

  return [
    const PermissionReasonSummary(
      label: 'Location',
      reason: TripUxCopy.permissionReasonLocation,
    ),
    const PermissionReasonSummary(
      label: 'Background',
      reason: TripUxCopy.permissionReasonBackground,
    ),
    const PermissionReasonSummary(
      label: 'Notifications',
      reason: TripUxCopy.permissionReasonNotifications,
    ),
    if (includeActivityRecognition)
      const PermissionReasonSummary(
        label: 'Physical activity',
        reason: TripUxCopy.permissionReasonActivity,
      ),
    const PermissionReasonSummary(
      label: 'Battery',
      reason: TripUxCopy.permissionReasonBattery,
    ),
  ];
}

class PermissionReasonTable extends StatelessWidget {
  const PermissionReasonTable({
    super.key,
    this.includeActivityRecognition = true,
  });

  final bool includeActivityRecognition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = permissionReasonSummaries(
      includeActivityRecognition: includeActivityRecognition,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[index].label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[index].reason,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PermissionSetupItem {
  const PermissionSetupItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    this.reason,
    this.required = true,
    this.setupStep,
  });

  final String id;
  final String title;
  final String subtitle;
  /// Plain-language reason shown during onboarding (sleep-focused, not tech).
  final String? reason;
  final bool Function(AppPermissionSnapshot snapshot) isComplete;
  final bool required;
  final PermissionSetupStep? setupStep;
}

List<PermissionSetupItem> permissionSetupItems({
  bool requireActivityRecognition = false,
}) {
  return [
    PermissionSetupItem(
      id: 'gps',
      title: 'Phone GPS',
      reason: 'Know which stop you\'re passing',
      subtitle: 'Location services turned on',
      isComplete: (snapshot) => snapshot.locationServicesEnabled,
      setupStep: PermissionSetupStep.locationServices,
    ),
    PermissionSetupItem(
      id: 'location_when_in_use',
      title: Platform.isAndroid ? 'Location (step 1)' : 'Location',
      reason: 'Know which stop you\'re passing',
      subtitle: Platform.isAndroid
          ? 'Allow while using the app'
          : 'Allow While Using the App',
      isComplete: (snapshot) => snapshot.locationWhenInUseGranted,
      setupStep: PermissionSetupStep.locationWhenInUse,
    ),
    if (Platform.isAndroid)
      PermissionSetupItem(
        id: 'background_location',
        title: 'Location (step 2)',
        reason: 'Keep watching while your screen is off',
        subtitle: 'Allow all the time',
        isComplete: (snapshot) => snapshot.backgroundLocationGranted,
        setupStep: PermissionSetupStep.backgroundLocation,
      ),
    if (Platform.isAndroid)
      PermissionSetupItem(
        id: 'notifications',
        title: 'Notifications',
        reason: 'Wake you with sound and vibration',
        subtitle: 'Allowed',
        isComplete: (snapshot) => snapshot.notificationsGranted,
        setupStep: PermissionSetupStep.notifications,
      ),
    if (Platform.isAndroid)
      PermissionSetupItem(
        id: 'activity_recognition',
        title: 'Physical activity',
        reason: 'Tell when you\'re on the train vs waiting at the platform',
        subtitle: requireActivityRecognition ? 'Allowed' : 'Optional — enable in Location settings',
        isComplete: (snapshot) => snapshot.activityRecognitionGranted,
        required: requireActivityRecognition,
        setupStep: PermissionSetupStep.activityRecognition,
      ),
    if (Platform.isAndroid)
      PermissionSetupItem(
        id: 'battery',
        title: 'Battery',
        reason: 'So Android doesn\'t stop the trip',
        subtitle: 'Unrestricted / not optimized',
        isComplete: (snapshot) => snapshot.batteryUnrestricted,
        setupStep: PermissionSetupStep.batteryOptimization,
      ),
  ];
}

PermissionSetupItem? nextIncompleteSetupItem(
  AppPermissionSnapshot snapshot, {
  bool requireActivityRecognition = false,
}) {
  for (final item in permissionSetupItems(
    requireActivityRecognition: requireActivityRecognition,
  )) {
    if (item.required && !item.isComplete(snapshot)) {
      return item;
    }
  }
  return null;
}

PermissionSetupItem? nextRecommendedSetupItem(
  AppPermissionSnapshot snapshot, {
  bool requireActivityRecognition = false,
}) {
  for (final item in permissionSetupItems(
    requireActivityRecognition: requireActivityRecognition,
  )) {
    if (!item.isComplete(snapshot)) {
      return item;
    }
  }
  return null;
}

int requiredSetupStepCount({bool requireActivityRecognition = false}) {
  return permissionSetupItems(
    requireActivityRecognition: requireActivityRecognition,
  ).where((item) => item.required).length;
}

int completedRequiredSetupStepCount(
  AppPermissionSnapshot snapshot, {
  bool requireActivityRecognition = false,
}) {
  return permissionSetupItems(
    requireActivityRecognition: requireActivityRecognition,
  )
      .where((item) => item.required && item.isComplete(snapshot))
      .length;
}

bool needsBackgroundLocationRecovery(AppPermissionSnapshot snapshot) {
  return Platform.isAndroid &&
      snapshot.locationWhenInUseGranted &&
      !snapshot.backgroundLocationGranted;
}

PermissionSetupStep? setupStepForItemId(
  String id, {
  bool requireActivityRecognition = false,
}) {
  for (final item in permissionSetupItems(
    requireActivityRecognition: requireActivityRecognition,
  )) {
    if (item.id == id) {
      return item.setupStep;
    }
  }
  return null;
}

class PermissionStepProgressList extends StatelessWidget {
  const PermissionStepProgressList({
    super.key,
    required this.snapshot,
    this.activeStep,
    this.dimIncomplete = false,
    this.requireActivityRecognition = false,
  });

  final AppPermissionSnapshot snapshot;
  final PermissionSetupStep? activeStep;
  final bool dimIncomplete;
  final bool requireActivityRecognition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = permissionSetupItems(
      requireActivityRecognition: requireActivityRecognition,
    );
    final nextRequired = nextIncompleteSetupItem(
      snapshot,
      requireActivityRecognition: requireActivityRecognition,
    );

    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          _ProgressRow(
            index: index + 1,
            total: items.length,
            item: items[index],
            complete: items[index].isComplete(snapshot),
            isCurrent: items[index].setupStep != null &&
                items[index].setupStep == activeStep,
            isNextRequired: identical(items[index], nextRequired),
            dimIncomplete: dimIncomplete,
            colorScheme: colorScheme,
          ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.index,
    required this.total,
    required this.item,
    required this.complete,
    required this.isCurrent,
    required this.isNextRequired,
    required this.dimIncomplete,
    required this.colorScheme,
  });

  final int index;
  final int total;
  final PermissionSetupItem item;
  final bool complete;
  final bool isCurrent;
  final bool isNextRequired;
  final bool dimIncomplete;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final highlight = isCurrent || (isNextRequired && !complete);
    final icon = complete
        ? Icons.check_circle
        : highlight
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked;
    final iconColor = complete
        ? colorScheme.primary
        : highlight
            ? colorScheme.primary
            : colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.required ? 'Step' : 'Optional'} $index of $total · '
                  '${item.reason ?? item.title}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                    color: dimIncomplete && !complete && !highlight
                        ? colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.required
                      ? 'Set to: ${item.subtitle}'
                      : 'Recommended: ${item.subtitle}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: complete
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
