import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_permission_snapshot.dart';
import '../services/app_permissions_service.dart';

class PermissionSetupItem {
  const PermissionSetupItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    this.required = true,
    this.setupStep,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool Function(AppPermissionSnapshot snapshot) isComplete;
  final bool required;
  final PermissionSetupStep? setupStep;
}

List<PermissionSetupItem> permissionSetupItems() {
  return [
    PermissionSetupItem(
      id: 'gps',
      title: 'Phone GPS',
      subtitle: 'Location services turned on',
      isComplete: (snapshot) => snapshot.locationServicesEnabled,
      setupStep: PermissionSetupStep.locationServices,
    ),
    PermissionSetupItem(
      id: 'location_when_in_use',
      title: Platform.isAndroid ? 'Location (step 1)' : 'Location',
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
        subtitle: 'Allow all the time',
        isComplete: (snapshot) => snapshot.backgroundLocationGranted,
        setupStep: PermissionSetupStep.backgroundLocation,
      ),
    if (Platform.isAndroid)
      PermissionSetupItem(
        id: 'notifications',
        title: 'Notifications',
        subtitle: 'Allowed',
        isComplete: (snapshot) => snapshot.notificationsGranted,
        setupStep: PermissionSetupStep.notifications,
      ),
    if (Platform.isAndroid)
      PermissionSetupItem(
        id: 'battery',
        title: 'Battery',
        subtitle: 'Unrestricted / not optimized',
        isComplete: (snapshot) => snapshot.batteryUnrestricted,
        setupStep: PermissionSetupStep.batteryOptimization,
      ),
  ];
}

PermissionSetupItem? nextIncompleteSetupItem(AppPermissionSnapshot snapshot) {
  for (final item in permissionSetupItems()) {
    if (item.required && !item.isComplete(snapshot)) {
      return item;
    }
  }
  return null;
}

PermissionSetupItem? nextRecommendedSetupItem(AppPermissionSnapshot snapshot) {
  for (final item in permissionSetupItems()) {
    if (!item.isComplete(snapshot)) {
      return item;
    }
  }
  return null;
}

int requiredSetupStepCount() {
  return permissionSetupItems().where((item) => item.required).length;
}

int completedRequiredSetupStepCount(AppPermissionSnapshot snapshot) {
  return permissionSetupItems()
      .where((item) => item.required && item.isComplete(snapshot))
      .length;
}

bool needsBackgroundLocationRecovery(AppPermissionSnapshot snapshot) {
  return Platform.isAndroid &&
      snapshot.locationWhenInUseGranted &&
      !snapshot.backgroundLocationGranted;
}

PermissionSetupStep? setupStepForItemId(String id) {
  for (final item in permissionSetupItems()) {
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
  });

  final AppPermissionSnapshot snapshot;
  final PermissionSetupStep? activeStep;
  final bool dimIncomplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = permissionSetupItems();
    final nextRequired = nextIncompleteSetupItem(snapshot);

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
                  '${item.title}',
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
