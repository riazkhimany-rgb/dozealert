import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../models/favorite_destination.dart';
import '../providers/destination_history_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/trip_ux_copy.dart';
import 'accessible_scroll_body.dart';

/// Top 3 recent + all saved destinations/stops for one-tap reuse from Home.
class QuickPicksSheet extends StatelessWidget {
  const QuickPicksSheet({super.key});

  static const _maxRecent = 3;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const QuickPicksSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transitMode = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final history = context.watch<DestinationHistoryProvider>();
    final recents = history.recents.take(_maxRecent).toList(growable: false);
    final saved = history.favorites;
    final selected = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );

    final recentTitle = transitMode
        ? TripUxCopy.recentStopsTitle
        : TripUxCopy.recentDestinationsTitle;
    final savedTitle = transitMode
        ? TripUxCopy.savedStopsTitle
        : TripUxCopy.savedDestinationsTitle;

    return AccessibleSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TripUxCopy.quickPicksTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (recents.isEmpty && saved.isEmpty)
            Text(
              transitMode
                  ? TripUxCopy.noQuickPicksStopsYet
                  : TripUxCopy.noQuickPicksDestinationsYet,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            if (recents.isNotEmpty) ...[
              Text(
                recentTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...recents.map(
                (destination) => _QuickPickTile(
                  title: destination.name,
                  selected: selected != null &&
                      destination.name == selected.name &&
                      destination.latitude == selected.latitude &&
                      destination.longitude == selected.longitude,
                  icon: Icons.history,
                  onTap: () => unawaited(
                    _selectRecent(context, destination),
                  ),
                ),
              ),
              if (saved.isNotEmpty) const SizedBox(height: 16),
            ],
            if (saved.isNotEmpty) ...[
              Text(
                savedTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...saved.map(
                (item) => _QuickPickTile(
                  title: item.destination.name,
                  subtitle:
                      item.badges.isEmpty ? null : item.badges.join(', '),
                  selected: selected != null && item.matches(selected),
                  icon: Icons.star_outline,
                  onTap: () => unawaited(_selectSaved(context, item)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static Future<void> _selectRecent(
    BuildContext context,
    Destination destination,
  ) async {
    await context.read<GtfsProvider>().selectDestinationWithTransit(
      destination,
    );
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${destination.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static Future<void> _selectSaved(
    BuildContext context,
    FavoriteDestination item,
  ) async {
    await context.read<GtfsProvider>().selectFavoriteDestination(item);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${item.destination.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.selected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: selected
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        child: Icon(
          icon,
          size: 18,
          color: selected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: selected ? Icon(Icons.check, color: colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
