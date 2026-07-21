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

/// Quick destination pick from saved + recent on the Home destination card.
class FavoriteDestinationChips extends StatelessWidget {
  const FavoriteDestinationChips({super.key, this.maxChips = 3});

  final int maxChips;

  @override
  Widget build(BuildContext context) {
    final transitMode = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final favorites = context.watch<DestinationHistoryProvider>().favorites;
    final recents = context.watch<DestinationHistoryProvider>().recents;
    final selected = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );
    final isMonitoring = context.select<MonitoringProvider, bool>(
      (provider) => provider.isMonitoring,
    );

    if (isMonitoring) {
      return const SizedBox.shrink();
    }

    final chips = <_QuickChip>[];
    for (final item in favorites) {
      if (chips.length >= maxChips) {
        break;
      }
      chips.add(_QuickChip.favorite(item));
    }
    for (final destination in recents) {
      if (chips.length >= maxChips) {
        break;
      }
      final already = chips.any(
        (chip) => chip.matchesDestination(destination),
      );
      if (already) {
        continue;
      }
      chips.add(_QuickChip.recent(destination));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transitMode
              ? TripUxCopy.quickPicksStopsLabel
              : TripUxCopy.quickPicksDestinationsLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in chips)
              FilterChip(
                label: Text(chip.label),
                selected:
                    selected != null && chip.matchesDestination(selected),
                onSelected: (_) => unawaited(chip.select(context)),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuickChip {
  const _QuickChip._({
    required this.label,
    required this.favorite,
    required this.destination,
  });

  factory _QuickChip.favorite(FavoriteDestination item) {
    final name =
        item.destination.name.replaceAll(RegExp(r'\s+GO$'), '').trim();
    final label = item.badges.isEmpty ? name : '$name · ${item.badges.first}';
    return _QuickChip._(
      label: label,
      favorite: item,
      destination: item.destination,
    );
  }

  factory _QuickChip.recent(Destination destination) {
    final name = destination.name.replaceAll(RegExp(r'\s+GO$'), '').trim();
    return _QuickChip._(
      label: name,
      favorite: null,
      destination: destination,
    );
  }

  final String label;
  final FavoriteDestination? favorite;
  final Destination destination;

  bool matchesDestination(Destination other) {
    if (favorite != null) {
      return favorite!.matches(other);
    }
    return destination.name == other.name &&
        destination.latitude == other.latitude &&
        destination.longitude == other.longitude;
  }

  Future<void> select(BuildContext context) async {
    final gtfs = context.read<GtfsProvider>();
    if (favorite != null) {
      await gtfs.selectFavoriteDestination(favorite!);
    } else {
      await gtfs.selectDestinationWithTransit(destination);
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${destination.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
