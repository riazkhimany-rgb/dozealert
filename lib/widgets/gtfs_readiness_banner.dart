import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/transit_data_screen.dart';
import 'home_card.dart';

class GtfsReadinessBanner extends StatelessWidget {
  const GtfsReadinessBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<GtfsFeedProvider>();
    final preferences = context.watch<TransitProvider>().preferences;
    final transitSystem = preferences.transitSystem;

    if (!TransitCatalog.hasCatalogLines(transitSystem)) {
      return const SizedBox.shrink();
    }

    if (!feedProvider.isInitialized) {
      return const SizedBox.shrink();
    }

    final feed = feedProvider.feedForTransitSystem(transitSystem);
    if (feed == null || feed.status == GtfsFeedStatus.downloaded) {
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
                    'Download $transitSystem data to pick stops',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GTFS feed is required before you can search stops on '
                    'this agency.',
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
