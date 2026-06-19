import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_destinations.dart';
import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_provider.dart';
import '../widgets/home_card.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recentDestinations = context.select<TransitProvider, List<Destination>>(
      (provider) => provider.recentStations.take(5).toList(growable: false),
    );
    final missedTrip = context.select<MonitoringProvider, bool>(
      (provider) => provider.currentState == MonitoringState.missed,
    );
    final currentDestination = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _TripSection(
            title: 'Recent Destinations',
            icon: Icons.history,
            emptyMessage: 'No recent destinations yet.',
            destinations: recentDestinations,
          ),
          const SizedBox(height: 16),
          _TripSection(
            title: 'Favorite Destinations',
            icon: Icons.star_outline,
            emptyMessage: 'No favorite destinations saved.',
            destinations: MockDestinations.favorites
                .map((item) => item.destination)
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeCardHeader(
                  icon: Icons.route_outlined,
                  title: 'Trip History',
                ),
                const SizedBox(height: 12),
                Text(
                  'Trip history will appear here after completed journeys.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (currentDestination != null) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(currentDestination.name),
                    subtitle: const Text('Current destination'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeCardHeader(
                  icon: Icons.warning_amber_outlined,
                  title: 'Missed Trips',
                ),
                const SizedBox(height: 12),
                Text(
                  missedTrip && currentDestination != null
                      ? 'Missed wake-up for ${currentDestination.name}.'
                      : 'No missed trips recorded.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              (destination) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(destination.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.read<MonitoringProvider>().setDestination(destination);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${destination.name}')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
