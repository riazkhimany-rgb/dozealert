import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../models/favorite_destination.dart';
import '../models/trip_history_entry.dart';
import '../providers/destination_history_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/trip_history_provider.dart';
import '../widgets/home_card.dart';

String _formatTripTimestamp(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recentDestinations =
        context.select<DestinationHistoryProvider, List<Destination>>(
      (provider) => provider.recents.take(5).toList(growable: false),
    );
    final favorites =
        context.select<DestinationHistoryProvider, List<FavoriteDestination>>(
      (provider) => provider.favorites,
    );
    final history = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.completedTrips.take(10).toList(growable: false),
    );
    final missedTrips = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.missedTrips.take(10).toList(growable: false),
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
          _FavoriteSection(favorites: favorites),
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
                onTap: () => _selectDestination(context, destination),
              ),
            ),
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
          const HomeCardHeader(
            icon: Icons.star_outline,
            title: 'Favorite Destinations',
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
              (item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_outline),
                  title: Text(item.destination.name),
                  subtitle: item.badges.isEmpty
                      ? null
                      : Text(item.badges.join(', ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove favorite',
                    onPressed: () async {
                      await context
                          .read<DestinationHistoryProvider>()
                          .removeFavorite(item.destination);
                    },
                  ),
                  onTap: () => _selectDestination(context, item.destination),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.entries,
    this.highlightMissed = false,
  });

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<TripHistoryEntry> entries;
  final bool highlightMissed;

  @override
  Widget build(BuildContext context) {
    final dateFormat = _formatTripTimestamp;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(icon: icon, title: title),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...entries.map(
              (entry) {
                final end = entry.tripEnd ?? entry.tripStart;
                final subtitle = highlightMissed
                    ? 'Missed on ${dateFormat(end)}'
                    : entry.alarmDismissed != null
                        ? 'Dismissed ${dateFormat(entry.alarmDismissed!)}'
                        : 'Ended ${dateFormat(end)}';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    highlightMissed
                        ? Icons.warning_amber_outlined
                        : Icons.check_circle_outline,
                    color: highlightMissed
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  title: Text(entry.destination),
                  subtitle: Text(subtitle),
                );
              },
            ),
        ],
      ),
    );
  }
}

Future<void> _selectDestination(
  BuildContext context,
  Destination destination,
) async {
  await context.read<MonitoringProvider>().setDestination(destination);
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Selected ${destination.name}')),
  );
}
