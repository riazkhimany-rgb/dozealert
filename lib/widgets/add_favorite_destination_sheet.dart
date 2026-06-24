import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../models/transit_stop.dart';
import '../providers/destination_history_provider.dart';
import '../providers/monitoring_provider.dart';
import 'stop_picker_sheet.dart';
import 'accessible_scroll_body.dart';

class AddFavoriteDestinationSheet extends StatelessWidget {
  const AddFavoriteDestinationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const AddFavoriteDestinationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentDestination = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );
    final recents = context.select<DestinationHistoryProvider, List<Destination>>(
      (provider) => provider.recents,
    );
    final favorites = context.watch<DestinationHistoryProvider>().favorites;

    return AccessibleSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Add favorite stop',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save a stop for quick access when setting your destination.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (currentDestination != null)
              _AddOption(
                icon: Icons.my_location_outlined,
                title: 'Add current destination',
                subtitle: currentDestination.name,
                onTap: () => unawaited(
                  _addDestination(context, currentDestination),
                ),
              ),
            _AddOption(
              icon: Icons.route_outlined,
              title: 'Pick stop',
              subtitle: 'Search GTFS stops on your route',
              onTap: () {
                Navigator.of(context).pop();
                unawaited(
                  StopPickerSheet.show(
                    context,
                    onStopSelected: (stop) async {
                      await _addFromStop(context, stop);
                    },
                  ),
                );
              },
            ),
            if (recents.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Recent destinations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...recents.take(8).map((destination) {
                final alreadySaved = favorites.any(
                  (item) => item.matches(destination),
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(destination.name),
                  trailing: alreadySaved
                      ? Text(
                          'Saved',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Add to favorites',
                          onPressed: () =>
                              unawaited(_addDestination(context, destination)),
                        ),
                  onTap: alreadySaved
                      ? null
                      : () => unawaited(_addDestination(context, destination)),
                );
              }),
            ],
          ],
      ),
    );
  }

  static Future<void> _addFromStop(
    BuildContext context,
    TransitStop stop,
  ) async {
    final destination = Destination(
      name: stop.stopName,
      latitude: stop.latitude,
      longitude: stop.longitude,
    );
    await _addDestination(context, destination);
  }

  static Future<void> _addDestination(
    BuildContext context,
    Destination destination,
  ) async {
    final history = context.read<DestinationHistoryProvider>();
    if (history.isFavorite(destination)) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${destination.name} is already a favorite'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await history.addFavorite(destination);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${destination.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
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
