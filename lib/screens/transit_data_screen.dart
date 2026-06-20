import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../utils/user_facing_errors.dart';
import '../widgets/home_card.dart';

class TransitDataScreen extends StatefulWidget {
  const TransitDataScreen({super.key});

  @override
  State<TransitDataScreen> createState() => _TransitDataScreenState();
}

class _TransitDataScreenState extends State<TransitDataScreen> {
  String? _busyFeedId;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _confirmYrtAcknowledgement(GtfsFeedInfo feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('YRT Open Data'),
          content: Text(
            feed.acknowledgementMessage ??
                'YRT requires you to review their open data terms before '
                'downloading GTFS data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _openDataPage(GtfsFeedInfo feed) async {
    final url = feed.openDataPageUrl;
    if (url == null) {
      return;
    }

    if (feed.requiresUserAcknowledgement) {
      final confirmed = await _confirmYrtAcknowledgement(feed);
      if (!confirmed || !mounted) {
        return;
      }
    }

    await _launchUrl(url);
  }

  Future<void> _runFeedAction(
    String feedId,
    Future<void> Function() action,
  ) async {
    setState(() => _busyFeedId = feedId);
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transit feed updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserFacingErrors.from(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyFeedId = null);
      }
    }
  }

  Future<void> _importZip(GtfsFeedProvider feedProvider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected file.')),
      );
      return;
    }

    setState(() => _busyFeedId = 'import');
    try {
      await feedProvider.importZipBytes(
        bytes: bytes,
        fileName: file.name,
      );
      if (!mounted) {
        return;
      }
      await context.read<GtfsProvider>().refreshFromCache();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${file.name}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserFacingErrors.from(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyFeedId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<GtfsFeedProvider>();
    final preferences = context.watch<TransitProvider>().preferences;
    final colorScheme = Theme.of(context).colorScheme;
    final regionFeeds = feedProvider.feedsForRegion(
      preferences.country,
      preferences.region,
    );
    final regionLabel = TransitCatalog.regionLabelForCountry(
      preferences.country,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeCardHeader(
                  icon: Icons.cloud_download_outlined,
                  title: '${preferences.region} GTFS Feeds',
                ),
                const SizedBox(height: 12),
                Text(
                  'Download GTFS feeds for agencies in ${preferences.region} '
                  '(${preferences.country}). Change your $regionLabel under '
                  'Settings → Transit → Preferred Agencies to browse other regions.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busyFeedId == 'import'
                        ? null
                        : () => _importZip(feedProvider),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Import GTFS Zip'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!feedProvider.isInitialized)
            const Center(child: CircularProgressIndicator())
          else if (regionFeeds.isEmpty)
            HomeCard(
              child: Text(
                'No GTFS feeds are configured for ${preferences.region} yet. '
                'Select another $regionLabel under Preferred Agencies, or import '
                'a GTFS zip manually.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...regionFeeds.map(
              (feed) => _FeedCard(
                feed: feed,
                isBusy: _busyFeedId == feed.feedId,
                errorMessage: feedProvider.errorFor(feed.feedId),
                onDownload: feed.hasDirectDownload
                    ? () => _runFeedAction(
                        feed.feedId,
                        () => feedProvider.downloadFeed(feed.feedId),
                      )
                    : null,
                onUpdate: feed.hasDirectDownload && feed.isDownloaded
                    ? () => _runFeedAction(
                        feed.feedId,
                        () => feedProvider.updateFeed(feed.feedId),
                      )
                    : null,
                onDelete: feed.isDownloaded
                    ? () => _runFeedAction(
                        feed.feedId,
                        () => feedProvider.deleteFeed(feed.feedId),
                      )
                    : null,
                onOpenDataPage: feed.hasOpenDataPage
                    ? () => _openDataPage(feed)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.feed,
    required this.isBusy,
    this.onDownload,
    this.onUpdate,
    this.onDelete,
    this.onOpenDataPage,
    this.errorMessage,
  });

  final GtfsFeedInfo feed;
  final bool isBusy;
  final VoidCallback? onDownload;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenDataPage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastUpdated = feed.lastUpdated == null
        ? '—'
        : MaterialLocalizations.of(context).formatShortDate(feed.lastUpdated!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HomeCard(
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
            _MetricRow(label: 'Vehicle types', value: feed.vehicleTypesLabel),
            const SizedBox(height: 8),
            _MetricRow(label: 'Last Updated', value: lastUpdated),
            const SizedBox(height: 8),
            _MetricRow(label: 'Stops', value: '${feed.stopCount}'),
            const SizedBox(height: 8),
            _MetricRow(label: 'Routes', value: '${feed.routeCount}'),
            if (feed.supportsRealtime) ...[
              const SizedBox(height: 8),
              Text(
                'Supports realtime',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onDownload != null)
                  FilledButton.icon(
                    onPressed: isBusy ? null : onDownload,
                    icon: isBusy
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download'),
                  ),
                if (onUpdate != null)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onUpdate,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Update'),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                if (onOpenDataPage != null)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onOpenDataPage,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(feed.openDataPageLabel ?? 'Open Data Page'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
