import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/destination_history_provider.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/gtfs_provider.dart';
import '../screens/map_picker_screen.dart';
import 'favorite_lines_picker_sheet.dart';
import 'favorite_stops_picker_sheet.dart';
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
    final canPickStop = context.watch<GtfsProvider>().canShowStopPicker();
    final favoriteStopCount =
        context.watch<DestinationHistoryProvider>().favorites.length;
    final favoriteLineCount =
        context.watch<FavoriteTransitLineProvider>().favorites.length;

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
              'Choose how you want to pick your stop or location.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _PickerOption(
              icon: Icons.map_outlined,
              title: 'Search on map',
              subtitle: 'Drop a pin or search with Google Places',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MapPickerScreen(),
                  ),
                );
              },
            ),
            if (canPickStop)
              _PickerOption(
                icon: Icons.route_outlined,
                title: 'Pick stop',
                subtitle: 'Search GTFS stops on your route',
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
              icon: Icons.swap_horiz,
              title: 'Quick switch line',
              subtitle: favoriteLineCount == 0
                  ? 'No saved lines yet'
                  : '$favoriteLineCount saved line${favoriteLineCount == 1 ? '' : 's'}',
              onTap: () {
                Navigator.of(context).pop();
                FavoriteLinesPickerSheet.show(context);
              },
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: colorScheme.surfaceContainerHighest,
        onTap: onTap,
      ),
    );
  }
}
