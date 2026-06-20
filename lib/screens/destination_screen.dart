import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_destination.dart';
import '../models/destination.dart';
import '../providers/destination_history_provider.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/home_card.dart';
import 'map_picker_screen.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isSearching => _query.isNotEmpty;

  List<FavoriteDestination> _filteredFavorites(
    List<FavoriteDestination> favorites,
  ) {
    if (!_isSearching) {
      return favorites;
    }

    return favorites
        .where(
          (item) => item.destination.name.toLowerCase().contains(_query),
        )
        .toList(growable: false);
  }

  Future<void> _selectDestination(Destination destination) async {
    await context.read<MonitoringProvider>().setDestination(destination);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final favorites = context.watch<DestinationHistoryProvider>().favorites;
    final destinations = _filteredFavorites(favorites);
    final selectedDestination =
        context.watch<MonitoringProvider>().selectedDestination;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Destination'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Filter favorites',
              leading: const Icon(Icons.search),
              trailing: _query.isEmpty
                  ? null
                  : [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      ),
                    ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MapPickerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Search on Map'),
              ),
            ),
          ),
          Expanded(
            child: destinations.isEmpty
                ? Center(
                    child: Text(
                      'No favorites match your search.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      if (!_isSearching) ...[
                        Text(
                          'Favorites',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ...destinations.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DestinationListCard(
                            item: item,
                            isSelected:
                                selectedDestination == item.destination,
                            onTap: () =>
                                _selectDestination(item.destination),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DestinationListCard extends StatelessWidget {
  const _DestinationListCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final FavoriteDestination item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = item.destination;

    return HomeCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.place_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${destination.latitude.toStringAsFixed(4)}, '
                      '${destination.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.badges.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.badges
                            .map(
                              (badge) => Chip(
                                label: Text(badge),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
