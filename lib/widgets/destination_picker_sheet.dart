import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_provider.dart';
import '../screens/destination_screen.dart';
import '../screens/map_picker_screen.dart';
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
            _PickerOption(
              icon: Icons.star_outline,
              title: 'Favorites',
              subtitle: 'Pick from saved destinations',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DestinationScreen(),
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
          ],
        ),
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
