import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transit_line_option.dart';
import '../models/transit_vehicle_type.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/settings/preferred_agencies_screen.dart';
import 'gtfs_vehicle_type_download_prompt.dart';
import 'searchable_line_picker.dart';
import 'vehicle_type_filter_chips.dart';

class TransitAgencyLinePickerSheet extends StatefulWidget {
  const TransitAgencyLinePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    final preferences = context.read<TransitProvider>().preferences;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => TransitAgencyLinePickerSheet(
        key: ValueKey(preferences.transitSystem),
      ),
    );
  }

  @override
  State<TransitAgencyLinePickerSheet> createState() =>
      _TransitAgencyLinePickerSheetState();
}

class _TransitAgencyLinePickerSheetState
    extends State<TransitAgencyLinePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  TransitVehicleType? _vehicleTypeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectLine(String line) async {
    final transitProvider = context.read<TransitProvider>();
    final gtfsProvider = context.read<GtfsProvider>();
    await transitProvider.setDefaultLine(line);
    await gtfsProvider.syncTransitModeRouteForSelectedLine();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openFullSettings() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PreferredAgenciesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preferences = context.watch<TransitProvider>().preferences;
    final gtfsProvider = context.watch<GtfsProvider>();
    final vehicleTypes = gtfsProvider.availableVehicleTypesForSelectedAgency();
    final lineOptions = gtfsProvider.availableLineOptionsForSelectedAgency(
      vehicleType: _vehicleTypeFilter,
    );
    final filteredLines = lineOptions
        .where((option) => option.matchesQuery(_query))
        .toList(growable: false);
    final selectedLineName = lineOptions
            .any((option) => option.lineName == preferences.defaultLine)
        ? preferences.defaultLine
        : (lineOptions.isNotEmpty
            ? lineOptions.first.lineName
            : preferences.defaultLine);
    final selectedOption = lineOptions.firstWhere(
      (option) => option.lineName == selectedLineName,
      orElse: () => TransitLineOption(
        lineName: selectedLineName,
        displayLabel: gtfsProvider.displayLabelForSelectedLine(),
      ),
    );
    final showGtfsPrompt = _vehicleTypeFilter != null &&
        lineOptions.isEmpty &&
        vehicleTypes.contains(_vehicleTypeFilter);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Choose agency & line',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preferences.transitSystem,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedOption.singleLineLabel,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => unawaited(_openFullSettings()),
                    child: const Text('Change agency'),
                  ),
                ],
              ),
            ),
            if (vehicleTypes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: VehicleTypeFilterChips(
                  vehicleTypes: vehicleTypes,
                  selected: _vehicleTypeFilter,
                  onSelected: (type) {
                    setState(() => _vehicleTypeFilter = type);
                  },
                ),
              ),
            if (showGtfsPrompt && _vehicleTypeFilter != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: GtfsVehicleTypeDownloadPrompt(
                  transitSystem: preferences.transitSystem,
                  vehicleType: _vehicleTypeFilter!,
                  onDownloadComplete: () => setState(() {}),
                ),
              ),
            if (lineOptions.isEmpty && !showGtfsPrompt)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _vehicleTypeFilter == null
                      ? 'Download GTFS in Preferred Agencies to load routes '
                          'for ${preferences.transitSystem}.'
                      : 'No ${_vehicleTypeFilter!.label.toLowerCase()} routes loaded yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else if (lineOptions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search route number or name…',
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
              Expanded(
                child: filteredLines.isEmpty
                    ? Center(
                        child: Text(
                          'No routes match "$_query".',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + bottomInset),
                        itemCount: filteredLines.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = filteredLines[index];
                          return TransitLineListTile(
                            option: option,
                            selected: option.lineName == selectedLineName,
                            onTap: () => unawaited(_selectLine(option.lineName)),
                          );
                        },
                      ),
              ),
            ] else
              const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottomInset),
              child: OutlinedButton.icon(
                onPressed: () => unawaited(_openFullSettings()),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Preferred agencies & GTFS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
