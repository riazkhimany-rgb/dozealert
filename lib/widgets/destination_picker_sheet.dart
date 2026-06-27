import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../providers/destination_history_provider.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/map_picker_screen.dart';
import '../screens/transit_data_screen.dart';
import '../utils/transit_user_copy.dart';
import 'favorite_lines_picker_sheet.dart';
import 'favorite_stops_picker_sheet.dart';
import 'recent_destinations_picker_sheet.dart';
import 'accessible_scroll_body.dart';
import 'stop_picker_sheet.dart';

class DestinationPickerSheet extends StatelessWidget {
  const DestinationPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return const DestinationPickerSheet();
      },
    );
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
    final favoriteStopCount =
        context.watch<DestinationHistoryProvider>().favorites.length;
    final favoriteLineCount =
        context.watch<FavoriteTransitLineProvider>().favorites.length;
    final recentCount =
        context.watch<DestinationHistoryProvider>().recents.length;
    final needsStopData = transitMode &&
        !canPickStop &&
        TransitCatalog.hasCatalogLines(agency);

    return AccessibleSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set destination',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transitMode
                ? 'Pick the stop where you want to wake up.'
                : 'Choose how you want to pick your stop or location.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (needsStopData) ...[
            const SizedBox(height: 16),
            _StopDataPromptCard(agencyName: agency),
          ],
          const SizedBox(height: 16),
          if (canPickStop)
            _PickerOption(
              icon: Icons.route_outlined,
              title: 'Pick stop',
              subtitle: TransitUserCopy.pickStopSubtitle,
              emphasized: transitMode,
              onTap: () {
                Navigator.of(context).pop();
                StopPickerSheet.show(context);
              },
            ),
          _PickerOption(
            icon: Icons.star_outline,
            title: 'Favorite destinations',
            subtitle: favoriteStopCount == 0
                ? 'No saved destinations yet'
                : '$favoriteStopCount saved destination${favoriteStopCount == 1 ? '' : 's'}',
            onTap: () {
              Navigator.of(context).pop();
              FavoriteStopsPickerSheet.show(context);
            },
          ),
          _PickerOption(
            icon: Icons.history,
            title: 'Recent destinations',
            subtitle: recentCount == 0
                ? 'No recent destinations yet'
                : '$recentCount recent destination${recentCount == 1 ? '' : 's'}',
            onTap: () {
              Navigator.of(context).pop();
              RecentDestinationsPickerSheet.show(context);
            },
          ),
          _PickerOption(
            icon: Icons.swap_horiz,
            title: 'Switch transit line',
            subtitle: favoriteLineCount == 0
                ? 'No saved lines yet'
                : '$favoriteLineCount saved line${favoriteLineCount == 1 ? '' : 's'}',
            onTap: () {
              Navigator.of(context).pop();
              FavoriteLinesPickerSheet.show(context);
            },
          ),
          if (!transitMode || !canPickStop)
            _PickerOption(
              icon: Icons.map_outlined,
              title: 'Search on map',
              subtitle: transitMode
                  ? TransitUserCopy.mapPinSubtitle
                  : 'Drop a pin or search with Google Places',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MapPickerScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StopDataPromptCard extends StatelessWidget {
  const _StopDataPromptCard({required this.agencyName});

  final String agencyName;

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
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitDataScreen(),
                ),
              );
            },
            child: const Text('Download stops'),
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
