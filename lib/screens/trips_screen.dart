import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_transit_line.dart';
import '../models/favorite_destination.dart';
import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/destination_history_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/trip_history_provider.dart';
import '../screens/settings/activity_settings_screen.dart';
import '../services/background_monitor_service.dart';
import '../utils/location_format.dart';
import '../utils/trip_stats.dart';
import '../utils/trip_ux_copy.dart';
import '../widgets/add_favorite_destination_sheet.dart';
import '../widgets/favorite_transit_lines_section.dart';
import '../widgets/trip_ready_sheet.dart';
import '../widgets/trip_stop_picker_sheet.dart';
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
    final stats = context.select<TripHistoryProvider, TripStats>(
      (provider) => provider.stats,
    );
    final transitModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final hasAnyTrips = recentDestinations.isNotEmpty ||
        favorites.isNotEmpty ||
        (transitModeEnabled && lineFavorites.isNotEmpty);
    final emptyActionLabel = transitModeEnabled
        ? TripUxCopy.pickYourStop
        : TripUxCopy.pickDestination;
    final emptyMessage = transitModeEnabled
        ? TripUxCopy.myTripsEmptyMessage
        : TripUxCopy.myTripsEmptyMessageDistance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(TripUxCopy.myTripsTab),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (stats.hasData) ...[
            _TripStatsTeaser(stats: stats),
            const SizedBox(height: 16),
          ],
          if (!hasAnyTrips)
            HomeCard(
              child: EmptyStateMessage(
                showLogo: true,
                message: emptyMessage,
                actionLabel: emptyActionLabel,
                onAction: () => TripStopPickerSheet.show(context),
              ),
            )
          else ...[
            _FavoriteSection(
              favorites: favorites,
              transitModeEnabled: transitModeEnabled,
            ),
            if (transitModeEnabled) ...[
              const SizedBox(height: 16),
              FavoriteTransitLinesSection(favorites: lineFavorites),
            ],
            const SizedBox(height: 16),
            _TripSection(
              title: transitModeEnabled
                  ? TripUxCopy.recentStopsTitle
                  : TripUxCopy.recentDestinationsTitle,
              icon: Icons.history,
              iconColor: const Color(0xFF4CC9F0),
              subtitle: transitModeEnabled
                  ? TripUxCopy.recentStopsSubtitle
                  : TripUxCopy.recentDestinationsSubtitle,
              emptyMessage: transitModeEnabled
                  ? TripUxCopy.noRecentStopsYet
                  : TripUxCopy.noRecentDestinationsYet,
              destinations: recentDestinations,
            ),
          ],
        ],
      ),
    );
  }
}

class _TripStatsTeaser extends StatelessWidget {
  const _TripStatsTeaser({required this.stats});

  final TripStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ActivitySettingsScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  TripStatsFormat.teaser(stats),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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
    this.iconColor,
    this.subtitle,
  });

  static const _collapsedVisibleCount = 2;

  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
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
            iconColor: widget.iconColor,
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
  const _FavoriteSection({
    required this.favorites,
    required this.transitModeEnabled,
  });

  final List<FavoriteDestination> favorites;
  final bool transitModeEnabled;

  @override
  Widget build(BuildContext context) {
    final title = transitModeEnabled
        ? TripUxCopy.savedStopsTitle
        : TripUxCopy.savedDestinationsTitle;
    final subtitle = transitModeEnabled
        ? TripUxCopy.savedStopsSubtitle
        : TripUxCopy.savedDestinationsSubtitle;
    final emptyMessage = transitModeEnabled
        ? TripUxCopy.noSavedStopsYet
        : TripUxCopy.noSavedDestinationsYet;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: HomeCardHeader(
                  icon: Icons.star_outline,
                  title: title,
                  iconColor: const Color(0xFF4CC9F0),
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
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (favorites.isEmpty)
            Text(
              emptyMessage,
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
              tooltip: TripUxCopy.useAndStartTrip,
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
  final proceed = await TripReadySheet.confirmStart(context);
  if (!proceed || !context.mounted) {
    return;
  }

  final locationProvider = context.read<LocationProvider>();
  final backgroundMonitorService = context.read<BackgroundMonitorService>();

  Future<void> tryStart({bool resume = false}) async {
    final result = await locationProvider.startTracking(resume: resume);
    if (!context.mounted) {
      return;
    }

    if (result == LocationStartResult.success && context.mounted) {
      await TripReadySheet.markTripStarted(context);
    }

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
