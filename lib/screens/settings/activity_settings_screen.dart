import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip_history_entry.dart';
import '../../providers/trip_history_provider.dart';
import '../../utils/trip_history_format.dart';
import '../../utils/trip_stats.dart';
import '../../widgets/home_card.dart';

class ActivitySettingsScreen extends StatelessWidget {
  const ActivitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.completedTrips,
    );
    final missedTrips =
        context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.missedTrips,
    );
    final entries = context.select<TripHistoryProvider, List<TripHistoryEntry>>(
      (provider) => provider.entries,
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
          _TripStatsCard(entries: entries),
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

class _TripStatsCard extends StatefulWidget {
  const _TripStatsCard({required this.entries});

  final List<TripHistoryEntry> entries;

  @override
  State<_TripStatsCard> createState() => _TripStatsCardState();
}

class _TripStatsCardState extends State<_TripStatsCard> {
  TripStatsWindow _window = TripStatsWindow.defaultWindow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = TripStats.fromEntries(widget.entries, window: _window);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.insights_outlined,
            title: 'Your trips',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final window in TripStatsWindow.values)
                FilterChip(
                  label: Text(window.label),
                  selected: _window == window,
                  onSelected: (_) {
                    if (_window == window) {
                      return;
                    }
                    setState(() => _window = window);
                  },
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!stats.hasData)
            Text(
              'No trips in the last ${_window.days} days.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(
                  label: 'Completed',
                  value: '${stats.completedCount}',
                ),
                _StatChip(
                  label: 'Missed',
                  value: '${stats.missedCount}',
                ),
                if (stats.successRate != null)
                  _StatChip(
                    label: 'Success',
                    value: TripStatsFormat.successRate(stats.successRate!),
                  ),
                _StatChip(
                  label: 'Streak',
                  value: '${stats.currentStreak}',
                ),
                if (stats.bestStreak > stats.currentStreak)
                  _StatChip(
                    label: 'Best streak',
                    value: '${stats.bestStreak}',
                  ),
                _StatChip(
                  label: 'Alarms',
                  value: '${stats.alarmsFiredCount}',
                ),
                if (stats.timeSlept > Duration.zero)
                  _StatChip(
                    label: 'Time slept',
                    value: TripStatsFormat.duration(stats.timeSlept),
                  ),
              ],
            ),
            if (stats.topDestinations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Top destinations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...stats.topDestinations.map(
                (dest) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dest.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        dest.count == 1 ? '1 trip' : '${dest.count} trips',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Stats cover the last ${_window.days} days. Time slept is from '
              'Start until your wake alarm (or trip end). Stopping early still '
              'counts as completed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
