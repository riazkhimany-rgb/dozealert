import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../providers/destination_history_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/map_picker_screen.dart';
import '../screens/transit_data_screen.dart';
import '../utils/transit_user_copy.dart';
import '../utils/trip_ux_copy.dart';
import 'accessible_scroll_body.dart';
import 'favorite_stops_picker_sheet.dart';
import 'recent_destinations_picker_sheet.dart';
import 'trip_stop_picker_sheet.dart';

/// Canonical entry for choosing a destination (stop or place).
class DestinationPickerSheet extends StatelessWidget {
  const DestinationPickerSheet({super.key, required this.hostContext});

  /// Context below this sheet for navigation after the sheet closes.
  final BuildContext hostContext;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DestinationPickerSheet(hostContext: context),
    );
  }

  void _closeThen(VoidCallback action) {
    Navigator.of(hostContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hostContext.mounted) return;
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gtfsProvider = context.watch<GtfsProvider>();
    final transitProvider = context.watch<TransitProvider>();
    final settings = context.watch<SettingsProvider>();
    final canPickStop = gtfsProvider.canShowStopPicker();
    final transitMode = settings.transitModeEnabled;
    final agency = transitProvider.preferences.transitSystem;
    final history = context.watch<DestinationHistoryProvider>();
    final savedCount = history.favorites.length;
    final recentCount = history.recents.length;
    final hasSavedOrRecent = savedCount > 0 || recentCount > 0;
    final needsStopData = transitMode &&
        !canPickStop &&
        TransitCatalog.hasCatalogLines(agency);
    final savedRecentSubtitle = '$savedCount saved · $recentCount recent';

    return AccessibleSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            transitMode ? TripUxCopy.pickYourStop : TripUxCopy.pickDestination,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transitMode
                ? 'Find the stop where you want to get off.'
                : 'Search on the map or drop a pin.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (needsStopData) ...[
            const SizedBox(height: 16),
            _StopDataPromptCard(
              agencyName: agency,
              onDownload: () => _closeThen(() {
                Navigator.of(hostContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TransitDataScreen(),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            _PickerOption(
              icon: Icons.map_outlined,
              title: 'Use map instead',
              subtitle: 'Wake by alert distance (no stop list needed)',
              onTap: () => _closeThen(() {
                Navigator.of(hostContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MapPickerScreen(),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 16),
          if (!transitMode)
            _PickerOption(
              icon: Icons.map_outlined,
              title: 'Search on map',
              subtitle: 'Drop a pin or search with Google Places',
              emphasized: true,
              onTap: () => _closeThen(() {
                Navigator.of(hostContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MapPickerScreen(),
                  ),
                );
              }),
            ),
          if (canPickStop && transitMode)
            _PickerOption(
              icon: Icons.route_outlined,
              title: 'Find a stop',
              subtitle: TransitUserCopy.pickStopSubtitle,
              emphasized: true,
              onTap: () => _closeThen(() {
                TripStopPickerSheet.show(hostContext);
              }),
            ),
          if (hasSavedOrRecent)
            _PickerOption(
              icon: Icons.bookmarks_outlined,
              title: TripUxCopy.savedAndRecentTitle,
              subtitle: savedRecentSubtitle,
              emphasized: !transitMode || !canPickStop,
              onTap: () => _closeThen(() {
                _SavedAndRecentPickerSheet.show(hostContext);
              }),
            ),
        ],
      ),
    );
  }
}

class _SavedAndRecentPickerSheet extends StatelessWidget {
  const _SavedAndRecentPickerSheet({required this.hostContext});

  final BuildContext hostContext;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _SavedAndRecentPickerSheet(hostContext: context),
    );
  }

  void _closeThen(VoidCallback action) {
    Navigator.of(hostContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hostContext.mounted) return;
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transitMode = context.watch<SettingsProvider>().transitModeEnabled;
    final favorites = context.watch<DestinationHistoryProvider>().favorites;
    final recents = context.watch<DestinationHistoryProvider>().recents;

    return AccessibleSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TripUxCopy.savedAndRecentTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (favorites.isNotEmpty)
            _PickerOption(
              icon: Icons.star_outline,
              title: transitMode
                  ? TripUxCopy.savedStopsTitle
                  : TripUxCopy.savedDestinationsTitle,
              subtitle: '${favorites.length} saved',
              onTap: () => _closeThen(() {
                FavoriteStopsPickerSheet.show(hostContext);
              }),
            ),
          if (recents.isNotEmpty)
            _PickerOption(
              icon: Icons.history,
              title: transitMode
                  ? TripUxCopy.recentStopsTitle
                  : TripUxCopy.recentDestinationsTitle,
              subtitle: '${recents.length} recent',
              onTap: () => _closeThen(() {
                RecentDestinationsPickerSheet.show(hostContext);
              }),
            ),
        ],
      ),
    );
  }
}

class _StopDataPromptCard extends StatelessWidget {
  const _StopDataPromptCard({
    required this.agencyName,
    required this.onDownload,
  });

  final String agencyName;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TransitUserCopy.downloadStopListFor(agencyName),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            TransitUserCopy.stopListNeededFor(agencyName),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Download stops'),
          ),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: emphasized
            ? colorScheme.primaryContainer.withValues(alpha: 0.45)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
