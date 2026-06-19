import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transit_stop.dart';
import '../providers/gtfs_provider.dart';

class StopPickerSheet extends StatefulWidget {
  const StopPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final sheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.75;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SizedBox(
            height: sheetHeight,
            child: const StopPickerSheet(),
          ),
        );
      },
    );
  }

  @override
  State<StopPickerSheet> createState() => _StopPickerSheetState();
}

class _StopPickerSheetState extends State<StopPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectStop(TransitStop stop) async {
    await context.read<GtfsProvider>().selectStop(stop);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gtfsProvider = context.watch<GtfsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final stops = gtfsProvider.filterStopsForSelectedLine(_query);

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Filter stops…',
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
            '${stops.length} stop${stops.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: stops.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _query.isEmpty
                          ? 'No stops available for this line.'
                          : 'No stops match "$_query".',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                      onTap: () => _selectStop(stop),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
