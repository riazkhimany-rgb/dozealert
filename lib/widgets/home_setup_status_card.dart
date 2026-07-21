import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/app_permission_snapshot.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/settings/permissions_settings_screen.dart';
import '../screens/transit_data_screen.dart';
import '../services/app_permissions_service.dart';
import '../utils/gtfs_readiness.dart';
import '../utils/transit_user_copy.dart';
import '../utils/trip_readiness.dart';
import '../utils/trip_ux_copy.dart';
import 'destination_picker_sheet.dart';
import 'home_card.dart';

/// Single Home status card for permissions / stop-data readiness and GTFS updates.
class HomeSetupStatusCard extends StatefulWidget {
  const HomeSetupStatusCard({super.key});

  @override
  State<HomeSetupStatusCard> createState() => _HomeSetupStatusCardState();
}

class _HomeSetupStatusCardState extends State<HomeSetupStatusCard>
    with WidgetsBindingObserver {
  AppPermissionSnapshot? _permissions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshPermissions());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissions());
    }
  }

  Future<void> _refreshPermissions() async {
    final snapshot = await context.read<AppPermissionsService>().snapshot();
    if (!mounted) {
      return;
    }
    setState(() => _permissions = snapshot);
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<GtfsFeedProvider>();
    final gtfsProvider = context.watch<GtfsProvider>();
    final preferences = context.watch<TransitProvider>().preferences;
    final settings = context.watch<SettingsProvider>();
    final hasDestination = context.select<MonitoringProvider, bool>(
      (provider) => provider.selectedDestination != null,
    );
    final isMonitoring = context.select<MonitoringProvider, bool>(
      (provider) => provider.isMonitoring,
    );

    if (isMonitoring) {
      return const SizedBox.shrink();
    }

    final isUpgrading = feedProvider.isUpgradingStaleFeeds;
    final readiness = TripReadiness.evaluate(
      transitModeEnabled: settings.transitModeEnabled,
      hasDestination: hasDestination,
      permissions: _permissions,
      preferences: preferences,
      gtfsProvider: gtfsProvider,
      feedProvider: feedProvider,
      requireActivityRecognition: settings.activityRecognitionEnabled,
    );

    final pending = readiness.items
        .where((item) => !item.complete)
        .where((item) => item.issue != TripReadinessIssue.destination)
        .toList(growable: false);

    final needsDownload = settings.transitModeEnabled &&
        TransitCatalog.hasCatalogLines(preferences.transitSystem) &&
        feedProvider.isInitialized &&
        gtfsProvider.isInitialized &&
        GtfsReadiness.shouldPromptForDownload(
          gtfsProvider,
          preferences,
          feedProvider,
        );

    if (!isUpgrading && pending.isEmpty && !needsDownload) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final agency = preferences.transitSystem;
    final feed = feedProvider.feedForTransitSystem(agency);
    final canDownloadInApp = feed?.hasDirectDownload ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUpgrading) ...[
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transit data updating…',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (pending.isNotEmpty || needsDownload) const SizedBox(height: 12),
            ],
            if (pending.isNotEmpty || needsDownload) ...[
              Text(
                TripUxCopy.setupBeforeStartTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...pending.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => unawaited(_handleAction(item)),
                        child: Text(item.actionLabel),
                      ),
                    ],
                  ),
                );
              }),
              if (needsDownload &&
                  !pending.any(
                    (item) => item.issue == TripReadinessIssue.stopData,
                  )) ...[
                Text(
                  TransitUserCopy.downloadStopListFor(agency),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  TransitUserCopy.stopListNeededFor(agency),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TransitDataScreen(),
                      ),
                    );
                  },
                  child: Text(
                    canDownloadInApp ? 'Download stops' : 'Get stop list',
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(TripReadinessItem item) async {
    switch (item.issue) {
      case TripReadinessIssue.destination:
        await DestinationPickerSheet.show(context);
      case TripReadinessIssue.permissions:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PermissionsSettingsScreen(),
          ),
        );
        await _refreshPermissions();
      case TripReadinessIssue.stopData:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TransitDataScreen(),
          ),
        );
    }
  }
}
