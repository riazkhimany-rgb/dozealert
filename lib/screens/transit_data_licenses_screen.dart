import 'package:flutter/material.dart';

import '../models/gtfs_feed_info.dart';
import '../models/transit_catalog_agency.dart';
import '../utils/external_link_launcher.dart';
import '../utils/transit_attribution.dart';
import '../utils/transit_data_licenses.dart';
import '../widgets/home_card.dart';

class TransitDataLicensesScreen extends StatelessWidget {
  const TransitDataLicensesScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    await ExternalLinkLauncher.openOrSnackBar(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bundledAgencies = TransitDataLicenses.bundledBootstrapAgencies;
    final feeds = TransitDataLicenses.licensedFeeds;
    final listedWithoutFeed = TransitDataLicenses.listedWithoutGtfsFeed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Data Licenses'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeCardHeader(
                  icon: Icons.gavel_outlined,
                  title: 'Open data notice',
                ),
                const SizedBox(height: 12),
                Text(
                  TransitDataLicenses.generalNotice,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeCardHeader(
                  icon: Icons.inventory_2_outlined,
                  title: 'Bundled stop lists',
                ),
                const SizedBox(height: 12),
                Text(
                  TransitDataLicenses.bundledNotice,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...bundledAgencies.map(
                  (agency) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${agency.agencyName} (${agency.lines.length} lines)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TransitAttribution.textForAgency(agency.agencyName),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Agency feeds',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attribution and how to obtain GTFS for each Ontario feed in DozeAlert.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...feeds.map(
            (feed) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeedLicenseCard(
                feed: feed,
                onOpenUrl: (url) => _launchUrl(context, url),
              ),
            ),
          ),
          if (listedWithoutFeed.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Listed agencies without in-app GTFS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'These appear in Preferred Agencies for line selection. Import a '
              'GTFS zip manually when you have one from the agency.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...listedWithoutFeed.map(
              (agency) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ListedAgencyCard(agency: agency),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

class _FeedLicenseCard extends StatelessWidget {
  const _FeedLicenseCard({
    required this.feed,
    required this.onOpenUrl,
  });

  final GtfsFeedInfo feed;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accessMode = feed.dataAccessMode;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feed.agencyName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feed.province,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accessMode == TransitDataAccessMode.inAppDownload
                  ? colorScheme.primaryContainer
                  : colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              accessMode.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accessMode == TransitDataAccessMode.inAppDownload
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            accessMode.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            feed.resolvedAttribution,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (feed.requiresUserAcknowledgement &&
              feed.acknowledgementMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              feed.acknowledgementMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (feed.resolvedLicenseUrl != null)
                OutlinedButton.icon(
                  onPressed: () => onOpenUrl(feed.resolvedLicenseUrl!),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('License / terms'),
                ),
              if (feed.hasOpenDataPage)
                OutlinedButton.icon(
                  onPressed: () => onOpenUrl(feed.openDataPageUrl!),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(feed.openDataPageLabel ?? 'Open data page'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListedAgencyCard extends StatelessWidget {
  const _ListedAgencyCard({required this.agency});

  final TransitCatalogAgency agency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            agency.agencyName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${agency.city}, ${agency.region}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Lines: ${agency.lines.join(', ')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            TransitAttribution.textForAgency(agency.agencyName),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No GTFS feed is configured in DozeAlert yet. Use Import GTFS Zip on '
            'Transit Data when you obtain data from the agency.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
