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

  List<Destination> get _filteredDestinations {
    if (_query.isEmpty) {
      return MockDestinations.all;
    }

    return MockDestinations.all
        .where((destination) => destination.name.toLowerCase().contains(_query))
        .toList();
  }

  void _selectDestination(Destination destination) {
    context.read<MonitoringProvider>().setDestination(destination);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destinations = _filteredDestinations;

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
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: destinations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      final selectedDestination = context
                          .watch<MonitoringProvider>()
                          .selectedDestination;
                      final isSelected =
                          selectedDestination == destination;

                      return HomeCard(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _selectDestination(destination),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.place_outlined,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        destination.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${destination.latitude.toStringAsFixed(4)}, '
                                        '${destination.longitude.toStringAsFixed(4)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
