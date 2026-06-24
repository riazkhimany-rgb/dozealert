import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/transit_data_screen.dart';
import '../utils/gtfs_readiness.dart';
import 'home_card.dart';

class GtfsReadinessBanner extends StatelessWidget {
  const GtfsReadinessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<GtfsFeedProvider>();
    final gtfsProvider = context.watch<GtfsProvider>();
    final preferences = context.watch<TransitProvider>().preferences;

    if (!TransitCatalog.hasCatalogLines(preferences.transitSystem)) {
      return const SizedBox.shrink();
    }

    if (!feedProvider.isInitialized || !gtfsProvider.isInitialized) {
      return const SizedBox.shrink();
    }

    if (!GtfsReadiness.shouldPromptForDownload(
      gtfsProvider,
      preferences,
      feedProvider,
    )) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HomeCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optional: download full ${preferences.transitSystem} data',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bundled stops work for main lines. Download the full GTFS '
                    'feed for every route and the latest schedule data.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TransitDataScreen(),
                        ),
                      );
                    },
                    child: const Text('Open Transit Data'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
