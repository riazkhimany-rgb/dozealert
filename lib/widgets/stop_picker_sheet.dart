import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gtfs_station.dart';
import '../models/gtfs_station_search_result.dart';
import '../models/transit_stop.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/transit_data_screen.dart';
import '../utils/transit_user_copy.dart';

enum _StopSearchScope { thisRoute, allRoutes }

class StopPickerSheet extends StatefulWidget {
  const StopPickerSheet({
    super.key,
    this.onStopSelected,
    this.compactHeader = false,
  });

  /// When set, called instead of applying the stop as the active destination.
  final Future<void> Function(TransitStop stop)? onStopSelected;

  /// Hides the sheet title when embedded in [TripStopPickerSheet].
  final bool compactHeader;

  static Future<bool> show(
    BuildContext context, {
    Future<void> Function(TransitStop stop)? onStopSelected,
  }) async {
    final selected = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final viewPadding = mediaQuery.viewPadding;
        final sheetHeight = (mediaQuery.size.height -
                viewPadding.top -
                viewPadding.bottom) *
            0.75;

        return Padding(
          padding: EdgeInsets.only(
            top: viewPadding.top,
            bottom: viewPadding.bottom + mediaQuery.viewInsets.bottom,
          ),
          child: SizedBox(
            height: sheetHeight,
            child: StopPickerSheet(onStopSelected: onStopSelected),
          ),
        );
      },
    );
    return selected ?? false;
  }

  @override
  State<StopPickerSheet> createState() => _StopPickerSheetState();
}

class _StopPickerSheetState extends State<StopPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  _StopSearchScope _scope = _StopSearchScope.thisRoute;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectStation(GtfsStation station) async {
    final customHandler = widget.onStopSelected;
    if (customHandler != null) {
      await customHandler(station.representativeStop);
      return;
    }

    await context.read<GtfsProvider>().selectStation(station);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gtfsProvider = context.watch<GtfsProvider>();
    final transitSystem = context.watch<TransitProvider>().preferences.transitSystem;
    final colorScheme = Theme.of(context).colorScheme;
    final hasLineStops = gtfsProvider.hasStopsForSelectedLine();
    final hasAgencyStops = gtfsProvider.hasStopsForSelectedAgency();
    final effectiveScope = hasLineStops
        ? _scope
        : _StopSearchScope.allRoutes;
    final showScopeToggle = hasLineStops && hasAgencyStops;

    final routeStations = effectiveScope == _StopSearchScope.thisRoute
        ? gtfsProvider.filterStationsForSelectedLine(_query)
        : const <GtfsStation>[];
    final agencyResults = effectiveScope == _StopSearchScope.allRoutes
        ? gtfsProvider.searchStationsForSelectedAgency(_query)
        : const <GtfsStationSearchResult>[];

    final resultCount = effectiveScope == _StopSearchScope.thisRoute
        ? routeStations.length
        : agencyResults.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compactHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Pick station',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              gtfsProvider.selectedLineLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              gtfsProvider.selectedLineLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (showScopeToggle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<_StopSearchScope>(
              segments: const [
                ButtonSegment(
                  value: _StopSearchScope.thisRoute,
                  label: Text('This route'),
                  icon: Icon(Icons.route_outlined, size: 18),
                ),
                ButtonSegment(
                  value: _StopSearchScope.allRoutes,
                  label: Text('All routes'),
                  icon: Icon(Icons.hub_outlined, size: 18),
                ),
              ],
              selected: {_scope},
              onSelectionChanged: (selection) {
                setState(() => _scope = selection.first);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SearchBar(
            controller: _searchController,
            hintText: effectiveScope == _StopSearchScope.allRoutes
                ? 'Search all stations…'
                : 'Filter stations…',
            leading: const Icon(Icons.search),
            trailing: _query.isEmpty
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                  ],
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '$resultCount station${resultCount == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: resultCount == 0
              ? _StopPickerEmptyState(
                  query: _query,
                  scope: effectiveScope,
                  hasAgencyStops: hasAgencyStops,
                  hasLineStops: hasLineStops,
                  transitSystem: transitSystem,
                )
              : effectiveScope == _StopSearchScope.thisRoute
                  ? _RouteStationList(
                      stations: routeStations,
                      onSelect: _selectStation,
                    )
                  : _AgencyStationList(
                      results: agencyResults,
                      onSelect: _selectStation,
                    ),
        ),
      ],
    );
  }
}

class _StopPickerEmptyState extends StatelessWidget {
  const _StopPickerEmptyState({
    required this.query,
    required this.scope,
    required this.hasAgencyStops,
    required this.hasLineStops,
    required this.transitSystem,
  });

  final String query;
  final _StopSearchScope scope;
  final bool hasAgencyStops;
  final bool hasLineStops;
  final String transitSystem;

  bool get _needsGtfsDownload => query.isEmpty && !hasAgencyStops;

  String get _message {
    if (query.isNotEmpty) {
      return 'No stations match "$query".';
    }
    if (!hasAgencyStops) {
      return TransitUserCopy.downloadStopListForTransit(transitSystem);
    }
    if (scope == _StopSearchScope.thisRoute && !hasLineStops) {
      return 'No stations available for this line. Try All routes.';
    }
    return TransitUserCopy.noStopsForTransit(transitSystem);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_needsGtfsDownload) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TransitDataScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Download transit data'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteStationList extends StatelessWidget {
  const _RouteStationList({
    required this.stations,
    required this.onSelect,
  });

  final List<GtfsStation> stations;
  final ValueChanged<GtfsStation> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: stations.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final station = stations[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '${station.representativeStop.stopSequence}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(station.name),
          onTap: () => onSelect(station),
        );
      },
    );
  }
}

class _AgencyStationList extends StatelessWidget {
  const _AgencyStationList({
    required this.results,
    required this.onSelect,
  });

  final List<GtfsStationSearchResult> results;
  final ValueChanged<GtfsStation> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.secondaryContainer,
            child: Icon(
              Icons.location_on_outlined,
              size: 18,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(result.station.name),
          subtitle: Text(result.routeName),
          onTap: () => onSelect(result.station),
        );
      },
    );
  }
}
