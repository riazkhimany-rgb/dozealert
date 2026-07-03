import 'package:flutter/material.dart';

import '../models/transit_mode_snapshot.dart';
import '../models/trip_pattern_concern.dart';
import '../utils/transit_wake_message.dart';

/// Prominent warning when route confidence is low (wrong direction / unlikely route).
class TripConcernBanner extends StatelessWidget {
  const TripConcernBanner({
    super.key,
    required this.snapshot,
    required this.selectedLine,
    required this.gpsSignalLost,
    required this.transitModeEnabled,
    required this.gtfsReady,
    required this.isMonitoring,
  });

  final TransitModeSnapshot snapshot;
  final String selectedLine;
  final bool gpsSignalLost;
  final bool transitModeEnabled;
  final bool gtfsReady;
  final bool isMonitoring;

  @override
  Widget build(BuildContext context) {
    final concern = snapshot.tripConcern;
    if (!isMonitoring || !snapshot.isActive || concern == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final (title, icon) = switch (concern) {
      TripPatternConcern.wrongDirection => (
        'Wrong direction?',
        Icons.swap_horiz_rounded,
      ),
      TripPatternConcern.unlikelyRoute => (
        'Route uncertain',
        Icons.help_outline_rounded,
      ),
      _ => ('Trip check needed', Icons.warning_amber_rounded),
    };

    final body = TransitWakeMessage.forHome(
      transitModeEnabled: transitModeEnabled,
      gtfsReady: gtfsReady,
      snapshot: snapshot,
      isMonitoring: isMonitoring,
      selectedLine: selectedLine,
      gpsSignalLost: gpsSignalLost,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.error, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your stop alarm is still armed — this is just a heads-up to '
                  'double-check your line and direction.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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
