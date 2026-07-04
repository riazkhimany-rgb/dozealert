import 'package:flutter/material.dart';

import '../providers/gtfs_feed_provider.dart';

/// Determinate GTFS download/import progress with a visible percentage.
class GtfsFeedProgressIndicator extends StatelessWidget {
  const GtfsFeedProgressIndicator({
    super.key,
    required this.progress,
  });

  final GtfsFeedProgress progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = progress.overallFraction.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                progress.phase,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${progress.percent}%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: fraction,
          minHeight: 6,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
