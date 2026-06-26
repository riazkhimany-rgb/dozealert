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
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/trip_history_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/location_format.dart';
import '../utils/trip_history_format.dart';
import '../widgets/add_favorite_destination_sheet.dart';
import '../widgets/favorite_transit_lines_section.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/home_card.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recentDestinations =
        context.select<DestinationHistoryProvider, List<Destination>>(
      (provider) => provider.recents,
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
      (provider) => provider.completedTrips,
    );
    final missedTrips = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.missedTrips,
    );
    final hasAnyTrips = recentDestinations.isNotEmpty ||
        favorites.isNotEmpty ||
        lineFavorites.isNotEmpty ||
        history.isNotEmpty ||
        missedTrips.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
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
            )
          else ...[
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
        ],
      ),
    );
  }
}

class _TripSection extends StatefulWidget {
  const _TripSection({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.destinations,
  });

  static const _collapsedVisibleCount = 2;

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<Destination> destinations;

  @override
  State<_TripSection> createState() => _TripSectionState();
}

class _TripSectionState extends State<_TripSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final destinations = widget.destinations;
    final hiddenCount =
        destinations.length - _TripSection._collapsedVisibleCount;
    final visibleDestinations = _expanded || hiddenCount <= 0
        ? destinations
        : destinations
            .take(_TripSection._collapsedVisibleCount)
            .toList(growable: false);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(
            icon: widget.icon,
            title: destinations.length > _TripSection._collapsedVisibleCount
                ? '${widget.title} (${destinations.length})'
                : widget.title,
          ),
          const SizedBox(height: 12),
          if (destinations.isEmpty)
            Text(
              widget.emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            ...visibleDestinations.map(
              (destination) => _DestinationListTile(
                destination: destination,
                onDelete: () async {
                  await context
                      .read<DestinationHistoryProvider>()
                      .removeRecent(destination);
                },
              ),
            ),
            if (hiddenCount > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'Show $hiddenCount more',
                  ),
                ),
              ),
          ],
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
                favorite: item,
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
    this.favorite,
    this.subtitle,
    this.onDelete,
  });

  final Destination destination;
  final FavoriteDestination? favorite;
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
                _selectAndStartMonitoring(
                  context,
                  destination,
                  favorite: favorite,
                ),
              ),
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove',
              onPressed: onDelete,
            ),
        ],
      ),
      onTap: () => unawaited(
        _selectDestination(context, destination, favorite: favorite),
      ),
    );
  }
}

class _HistorySection extends StatefulWidget {
  const _HistorySection({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.entries,
    this.highlightMissed = false,
  });

  static const _collapsedVisibleCount = 1;

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<TripHistoryEntry> entries;
  final bool highlightMissed;

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = TripHistoryFormat.friendlyTimestamp;
    final entries = widget.entries;
    final hiddenCount =
        entries.length - _HistorySection._collapsedVisibleCount;
    final visibleEntries = _expanded || hiddenCount <= 0
        ? entries
        : entries.take(_HistorySection._collapsedVisibleCount).toList();

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(
            icon: widget.icon,
            title: entries.length > 1
                ? '${widget.title} (${entries.length})'
                : widget.title,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              widget.emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            ...visibleEntries.map(
              (entry) => _HistoryEntryTile(
                entry: entry,
                highlightMissed: widget.highlightMissed,
                dateFormat: dateFormat,
              ),
            ),
            if (hiddenCount > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Show less' : 'Show $hiddenCount more',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({
    required this.entry,
    required this.highlightMissed,
    required this.dateFormat,
  });

  final TripHistoryEntry entry;
  final bool highlightMissed;
  final String Function(DateTime) dateFormat;

  @override
  Widget build(BuildContext context) {
    final end = entry.tripEnd ?? entry.tripStart;
    final subtitle = highlightMissed
        ? 'Missed ${dateFormat(end)}'
        : entry.alarmDismissed != null
            ? 'Dismissed ${dateFormat(entry.alarmDismissed!)}'
            : 'Ended ${dateFormat(end)}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        highlightMissed
            ? Icons.warning_amber_outlined
            : Icons.check_circle_outline,
        color: highlightMissed ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(entry.destination),
      subtitle: Text(subtitle),
    );
  }
}

Future<void> _applyDestinationSelection(
  BuildContext context,
  Destination destination, {
  FavoriteDestination? favorite,
}) async {
  final gtfsProvider = context.read<GtfsProvider>();
  if (favorite != null) {
    await gtfsProvider.selectFavoriteDestination(favorite);
  } else {
    await gtfsProvider.selectDestinationWithTransit(destination);
  }
}

Future<void> _selectDestination(
  BuildContext context,
  Destination destination, {
  FavoriteDestination? favorite,
}) async {
  await _applyDestinationSelection(
    context,
    destination,
    favorite: favorite,
  );
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
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.read<NavigationProvider>().setIndex(0);
                unawaited(_startMonitoringFromTrips(context));
              },
            ),
    ),
  );
}

Future<void> _selectAndStartMonitoring(
  BuildContext context,
  Destination destination, {
  FavoriteDestination? favorite,
}) async {
  await _applyDestinationSelection(
    context,
    destination,
    favorite: favorite,
  );
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

    if (!context.mounted) {
      return;
    }

    if (result == LocationStartResult.success ||
        context.read<MonitoringProvider>().currentState ==
            MonitoringState.monitoring) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  await tryStart();
}
