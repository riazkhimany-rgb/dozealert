import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../models/favorite_destination.dart';
import '../providers/destination_history_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/monitoring_provider.dart';

/// Quick destination pick from saved favorites on the Home destination card.
class FavoriteDestinationChips extends StatelessWidget {
  const FavoriteDestinationChips({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<DestinationHistoryProvider>().favorites;
    final selected = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );

    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorite stops',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in favorites)
              FilterChip(
                label: Text(_chipLabel(item)),
                selected: selected != null && item.matches(selected),
                onSelected: (_) =>
                    unawaited(_select(context, item)),
              ),
          ],
        ),
      ],
    );
  }

  static String _chipLabel(FavoriteDestination item) {
    final name = item.destination.name.replaceAll(RegExp(r'\s+GO$'), '').trim();
    if (item.badges.isEmpty) {
      return name;
    }
    return '$name · ${item.badges.first}';
  }

  static Future<void> _select(
    BuildContext context,
    FavoriteDestination item,
  ) async {
    await context.read<GtfsProvider>().selectFavoriteDestination(item);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${item.destination.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
