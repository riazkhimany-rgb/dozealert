import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_destinations.dart';
import '../models/destination.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/home_card.dart';

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

  List<DestinationCatalogItem> get _filteredDestinations {
    if (!_isSearching) {
      return MockDestinations.all;
    }

    return MockDestinations.all
        .where(
          (item) => item.destination.name.toLowerCase().contains(_query),
        )
        .toList();
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
    final destinations = _filteredDestinations;
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
              hintText: 'Search destinations',
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
          Expanded(
            child: destinations.isEmpty
                ? Center(
                    child: Text(
                      'No destinations match your search.',
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
                          'Recent Destinations',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...MockDestinations.recent.map(
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
                        const SizedBox(height: 8),
                        Text(
                          'All Destinations',
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
                            onTap: () => _selectDestination(item.destination),
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

  final DestinationCatalogItem item;
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
