import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_transit_line.dart';
import '../models/favorite_destination.dart';
import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../models/trip_history_entry.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/destination_history_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/trip_history_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/location_format.dart';
import '../widgets/add_favorite_destination_sheet.dart';
import '../widgets/favorite_transit_lines_section.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/home_card.dart';

String _formatTripTimestamp(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recentDestinations =
        context.select<DestinationHistoryProvider, List<Destination>>(
      (provider) => provider.recents.take(5).toList(growable: false),
    );
    final favorites =
        context.select<DestinationHistoryProvider, List<FavoriteDestination>>(
      (provider) => provider.favorites,
    );
    final lineFavorites =
        context.select<FavoriteTransitLineProvider, List<FavoriteTransitLine>>(
      (provider) => provider.favorites,
    );
    final history = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.completedTrips.take(10).toList(growable: false),
    );
    final missedTrips = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.missedTrips.take(10).toList(growable: false),
    );
    final hasAnyTrips = recentDestinations.isNotEmpty ||
        favorites.isNotEmpty ||
        lineFavorites.isNotEmpty ||
        history.isNotEmpty ||
        missedTrips.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (!hasAnyTrips)
            HomeCard(
              child: EmptyStateMessage(
                showLogo: true,
                message:
                    'Save favorite stops or complete a trip and they will appear here.',
                actionLabel: 'Set destination',
                onAction: () => DestinationPickerSheet.show(context),
              ),
            ),
          if (!hasAnyTrips) const SizedBox(height: 16),
          _TripSection(
            title: 'Recent Destinations',
            icon: Icons.history,
            emptyMessage: 'No recent destinations yet.',
            destinations: recentDestinations,
          ),
          const SizedBox(height: 16),
          _FavoriteSection(favorites: favorites),
          const SizedBox(height: 16),
          FavoriteTransitLinesSection(favorites: lineFavorites),
          const SizedBox(height: 16),
          _HistorySection(
            title: 'Trip History',
            icon: Icons.route_outlined,
            emptyMessage: 'Completed trips will appear here.',
            entries: history,
          ),
          const SizedBox(height: 16),
          _HistorySection(
            title: 'Missed Trips',
            icon: Icons.warning_amber_outlined,
            emptyMessage: 'No missed trips recorded.',
            entries: missedTrips,
            highlightMissed: true,
          ),
        ],
      ),
    );
  }
}

class _TripSection extends StatelessWidget {
  const _TripSection({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.destinations,
  });

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<Destination> destinations;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(icon: icon, title: title),
          const SizedBox(height: 12),
          if (destinations.isEmpty)
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...destinations.map(
              (destination) => _DestinationListTile(destination: destination),
            ),
        ],
      ),
    );
  }
}

class _FavoriteSection extends StatelessWidget {
  const _FavoriteSection({required this.favorites});

  final List<FavoriteDestination> favorites;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: HomeCardHeader(
                  icon: Icons.star_outline,
                  title: 'Favorite Destinations',
                  iconColor: Color(0xFF4CC9F0),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    unawaited(AddFavoriteDestinationSheet.show(context)),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Saved stops for quick access when setting your destination.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (favorites.isEmpty)
            Text(
              'No favorite destinations saved.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...favorites.map(
              (item) => _DestinationListTile(
                destination: item.destination,
                subtitle: item.badges.isEmpty ? null : item.badges.join(', '),
                onDelete: () async {
                  await context
                      .read<DestinationHistoryProvider>()
                      .removeFavorite(item.destination);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DestinationListTile extends StatelessWidget {
  const _DestinationListTile({
    required this.destination,
    this.subtitle,
    this.onDelete,
  });

  final Destination destination;
  final String? subtitle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isMonitoring = context.select<MonitoringProvider, MonitoringState>(
      (provider) => provider.currentState,
    ) == MonitoringState.monitoring;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.place_outlined),
      title: Text(destination.name),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMonitoring)
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: 'Use and start monitoring',
              onPressed: () => unawaited(
                _selectAndStartMonitoring(context, destination),
              ),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove favorite',
              onPressed: onDelete,
            ),
        ],
      ),
      onTap: () => unawaited(_selectDestination(context, destination)),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.entries,
    this.highlightMissed = false,
  });

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<TripHistoryEntry> entries;
  final bool highlightMissed;

  @override
  Widget build(BuildContext context) {
    final dateFormat = _formatTripTimestamp;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(icon: icon, title: title),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...entries.map(
              (entry) {
                final end = entry.tripEnd ?? entry.tripStart;
                final subtitle = highlightMissed
                    ? 'Missed on ${dateFormat(end)}'
                    : entry.alarmDismissed != null
                        ? 'Dismissed ${dateFormat(entry.alarmDismissed!)}'
                        : 'Ended ${dateFormat(end)}';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    highlightMissed
                        ? Icons.warning_amber_outlined
                        : Icons.check_circle_outline,
                    color: highlightMissed
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  title: Text(entry.destination),
                  subtitle: Text(subtitle),
                );
              },
            ),
        ],
      ),
    );
  }
}

Future<void> _selectDestination(
  BuildContext context,
  Destination destination,
) async {
  await context.read<MonitoringProvider>().setDestination(destination);
  if (!context.mounted) {
    return;
  }

  final isMonitoring = context.read<MonitoringProvider>().currentState ==
      MonitoringState.monitoring;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Selected ${destination.name}'),
      action: isMonitoring
          ? null
          : SnackBarAction(
              label: 'Start',
              onPressed: () {
                context.read<NavigationProvider>().setIndex(0);
                unawaited(_startMonitoringFromTrips(context));
              },
            ),
    ),
  );
}

Future<void> _selectAndStartMonitoring(
  BuildContext context,
  Destination destination,
) async {
  await context.read<MonitoringProvider>().setDestination(destination);
  if (!context.mounted) {
    return;
  }

  context.read<NavigationProvider>().setIndex(0);
  await _startMonitoringFromTrips(context);
}

Future<void> _startMonitoringFromTrips(BuildContext context) async {
  final locationProvider = context.read<LocationProvider>();
  final backgroundMonitorService = context.read<BackgroundMonitorService>();

  Future<void> tryStart({bool resume = false}) async {
    final result = await locationProvider.startTracking(resume: resume);
    if (!context.mounted) {
      return;
    }

    await LocationFeedback.handleStartResult(
      context,
      result,
      backgroundMonitorService: backgroundMonitorService,
      onContinueAfterBatteryPrompt:
          result == LocationStartResult.batteryOptimizationRequired
              ? () => tryStart(resume: true)
              : null,
    );
  }

  await tryStart();
}
