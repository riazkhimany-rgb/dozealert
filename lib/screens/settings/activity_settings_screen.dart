import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip_history_entry.dart';
import '../../providers/trip_history_provider.dart';
import '../../utils/trip_history_format.dart';
import '../../widgets/home_card.dart';

class ActivitySettingsScreen extends StatelessWidget {
  const ActivitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.completedTrips,
    );
    final missedTrips = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.missedTrips,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip history'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Past trips and alerts when you missed your stop.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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

class _HistorySection extends StatefulWidget {
  const _HistorySection({
    required this.title,
    required this.icon,
    required this.emptyMessage,
    required this.entries,
    this.highlightMissed = false,
  });

  static const _collapsedVisibleCount = 1;

  final String title;
  final IconData icon;
  final String emptyMessage;
  final List<TripHistoryEntry> entries;
  final bool highlightMissed;

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = TripHistoryFormat.friendlyTimestamp;
    final entries = widget.entries;
    final hiddenCount =
        entries.length - _HistorySection._collapsedVisibleCount;
    final visibleEntries = _expanded || hiddenCount <= 0
        ? entries
        : entries.take(_HistorySection._collapsedVisibleCount).toList();

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(
            icon: widget.icon,
            title: entries.length > 1
                ? '${widget.title} (${entries.length})'
                : widget.title,
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              widget.emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            ...visibleEntries.map(
              (entry) => _HistoryEntryTile(
                entry: entry,
                highlightMissed: widget.highlightMissed,
                dateFormat: dateFormat,
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

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({
    required this.entry,
    required this.highlightMissed,
    required this.dateFormat,
  });

  final TripHistoryEntry entry;
  final bool highlightMissed;
  final String Function(DateTime) dateFormat;

  @override
  Widget build(BuildContext context) {
    final end = entry.tripEnd ?? entry.tripStart;
    final subtitle = highlightMissed
        ? 'Missed ${dateFormat(end)}'
        : entry.alarmDismissed != null
            ? 'Dismissed ${dateFormat(entry.alarmDismissed!)}'
            : 'Ended ${dateFormat(end)}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        highlightMissed
            ? Icons.warning_amber_outlined
            : Icons.check_circle_outline,
        color: highlightMissed ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(entry.destination),
      subtitle: Text(subtitle),
    );
  }
}
