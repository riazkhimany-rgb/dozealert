import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transit_stop.dart';
import '../models/transit_stop_search_result.dart';
import '../providers/gtfs_provider.dart';
import '../screens/transit_data_screen.dart';

enum _StopSearchScope { thisRoute, allRoutes }

class StopPickerSheet extends StatefulWidget {
  const StopPickerSheet({
    super.key,
    this.onStopSelected,
  });

  /// When set, called instead of applying the stop as the active destination.
  final Future<void> Function(TransitStop stop)? onStopSelected;

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

  Future<void> _selectStop(TransitStop stop) async {
    final customHandler = widget.onStopSelected;
    if (customHandler != null) {
      await customHandler(stop);
    } else {
      await context.read<GtfsProvider>().selectStop(stop);
    }
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gtfsProvider = context.watch<GtfsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final hasLineStops = gtfsProvider.hasStopsForSelectedLine();
    final hasAgencyStops = gtfsProvider.hasStopsForSelectedAgency();
    final effectiveScope = hasLineStops
        ? _scope
        : _StopSearchScope.allRoutes;
    final showScopeToggle = hasLineStops && hasAgencyStops;

    final routeStops = effectiveScope == _StopSearchScope.thisRoute
        ? gtfsProvider.filterStopsForSelectedLine(_query)
        : const <TransitStop>[];
    final agencyResults = effectiveScope == _StopSearchScope.allRoutes
        ? gtfsProvider.searchStopsForSelectedAgency(_query)
        : const <TransitStopSearchResult>[];

    final resultCount = effectiveScope == _StopSearchScope.thisRoute
        ? routeStops.length
        : agencyResults.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Pick Stop',
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
                ? 'Search all stops…'
                : 'Filter stops…',
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
            '$resultCount stop${resultCount == 1 ? '' : 's'}',
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
                )
              : effectiveScope == _StopSearchScope.thisRoute
                  ? _RouteStopList(
                      stops: routeStops,
                      onSelect: _selectStop,
                    )
                  : _AgencyStopList(
                      results: agencyResults,
                      onSelect: _selectStop,
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
  });

  final String query;
  final _StopSearchScope scope;
  final bool hasAgencyStops;
  final bool hasLineStops;

  bool get _needsGtfsDownload => query.isEmpty && !hasAgencyStops;

  String get _message {
    if (query.isNotEmpty) {
      return 'No stops match "$query".';
    }
    if (!hasAgencyStops) {
      return 'Download transit data for this agency to browse and search stops.';
    }
    if (scope == _StopSearchScope.thisRoute && !hasLineStops) {
      return 'No stops available for this line. Try All routes.';
    }
    return 'No stops available for this agency.';
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

class _RouteStopList extends StatelessWidget {
  const _RouteStopList({
    required this.stops,
    required this.onSelect,
  });

  final List<TransitStop> stops;
  final ValueChanged<TransitStop> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: stops.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final stop = stops[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '${stop.stopSequence}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(stop.stopName),
          onTap: () => onSelect(stop),
        );
      },
    );
  }
}

class _AgencyStopList extends StatelessWidget {
  const _AgencyStopList({
    required this.results,
    required this.onSelect,
  });

  final List<TransitStopSearchResult> results;
  final ValueChanged<TransitStop> onSelect;

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
          title: Text(result.stop.stopName),
          subtitle: Text(result.routeName),
          onTap: () => onSelect(result.stop),
        );
      },
    );
  }
}
