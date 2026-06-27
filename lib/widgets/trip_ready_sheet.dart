import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/transit_data_screen.dart';
import '../services/app_permissions_service.dart';
import '../services/onboarding_service.dart';
import '../utils/trip_readiness.dart';
import '../widgets/branded_app_name.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/onboarding_permissions_page.dart';

/// Pre-start checklist — blocks Start until essentials are done, then
/// encourages first-time users with a friendly confirmation.
abstract final class TripReadySheet {
  static Future<bool> confirmStart(BuildContext context) async {
    final permissions = await context.read<AppPermissionsService>().snapshot();
    if (!context.mounted) {
      return false;
    }

    final settings = context.read<SettingsProvider>();
    final monitoring = context.read<MonitoringProvider>();
    final transit = context.read<TransitProvider>();
    final gtfsProvider = context.read<GtfsProvider>();
    final feedProvider = context.read<GtfsFeedProvider>();

    final snapshot = TripReadiness.evaluate(
      transitModeEnabled: settings.transitModeEnabled,
      hasDestination: monitoring.selectedDestination != null,
      permissions: permissions,
      preferences: transit.preferences,
      gtfsProvider: gtfsProvider,
      feedProvider: feedProvider,
    );

    if (!snapshot.isReady) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return _TripReadyChecklist(snapshot: snapshot);
        },
      );
      if (!context.mounted) {
        return false;
      }

      final refreshedPermissions =
          await context.read<AppPermissionsService>().snapshot();
      if (!context.mounted) {
        return false;
      }

      final refreshed = TripReadiness.evaluate(
        transitModeEnabled: context.read<SettingsProvider>().transitModeEnabled,
        hasDestination:
            context.read<MonitoringProvider>().selectedDestination != null,
        permissions: refreshedPermissions,
        preferences: context.read<TransitProvider>().preferences,
        gtfsProvider: context.read<GtfsProvider>(),
        feedProvider: context.read<GtfsFeedProvider>(),
      );
      if (!refreshed.isReady) {
        return false;
      }
    }

    final onboardingService = context.read<OnboardingService>();
    final hasStartedBefore = await onboardingService.hasStartedFirstTrip();
    if (!context.mounted) {
      return false;
    }

    if (hasStartedBefore) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.nightlight_round),
          title: const Text('Ready to rest?'),
          content: BrandedMentionText(
            'Tap Start, then relax. DozeAlert watches your trip in the '
            'background and wakes you before your stop.\n\n'
            'Keep your phone charged and volume on.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start my trip'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await onboardingService.markFirstTripStarted();
    }

    return confirmed ?? false;
  }

  static Future<void> markTripStarted(BuildContext context) async {
    await context.read<OnboardingService>().markFirstTripStarted();
  }
}

class _TripReadyChecklist extends StatelessWidget {
  const _TripReadyChecklist({required this.snapshot});

  final TripReadinessSnapshot snapshot;

  Future<void> _fixIssue(BuildContext context, TripReadinessIssue issue) async {
    Navigator.of(context).pop();

    switch (issue) {
      case TripReadinessIssue.destination:
        await DestinationPickerSheet.show(context);
      case TripReadinessIssue.permissions:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Permissions')),
              body: OnboardingPermissionsPage(onStatusChanged: (_) {}),
            ),
          ),
        );
      case TripReadinessIssue.stopData:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const TransitDataScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Almost ready',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete these steps before you fall asleep:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...snapshot.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.complete
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: item.complete
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                  title: Text(item.label),
                  trailing: item.complete
                      ? null
                      : FilledButton.tonal(
                          onPressed: () => _fixIssue(context, item.issue),
                          child: Text(item.actionLabel),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
