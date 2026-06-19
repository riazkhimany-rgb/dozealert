import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gtfs_feed_info.dart';
import '../models/transit_vehicle_type.dart';
import '../providers/gtfs_feed_provider.dart';
import '../widgets/home_card.dart';

class TransitDataScreen extends StatefulWidget {
  const TransitDataScreen({super.key});

  @override
  State<TransitDataScreen> createState() => _TransitDataScreenState();
}

class _TransitDataScreenState extends State<TransitDataScreen> {
  String? _busyFeedId;

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
        SnackBar(content: Text('Feed action failed: $error')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${file.name}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
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
    final colorScheme = Theme.of(context).colorScheme;

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
                const HomeCardHeader(
                  icon: Icons.cloud_download_outlined,
                  title: 'Offline Transit Feeds',
                ),
                const SizedBox(height: 12),
                Text(
                  'Download GTFS feeds for offline stop search and Transit Mode. '
                  'Once downloaded, no internet is required.',
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
          else
            ...feedProvider.feeds.map(
              (feed) => _FeedCard(
                feed: feed,
                isBusy: _busyFeedId == feed.feedId,
                errorMessage: feedProvider.errorFor(feed.feedId),
                onDownload: () => _runFeedAction(
                  feed.feedId,
                  () => feedProvider.downloadFeed(feed.feedId),
                ),
                onUpdate: () => _runFeedAction(
                  feed.feedId,
                  () => feedProvider.updateFeed(feed.feedId),
                ),
                onDelete: () => _runFeedAction(
                  feed.feedId,
                  () => feedProvider.deleteFeed(feed.feedId),
                ),
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
    required this.onDownload,
    required this.onUpdate,
    required this.onDelete,
    this.errorMessage,
  });

  final GtfsFeedInfo feed;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onDownload;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

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
              feed.vehicleType.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _MetricRow(label: 'Feed Status', value: feed.status.label),
            const SizedBox(height: 8),
            _MetricRow(label: 'Last Updated', value: lastUpdated),
            const SizedBox(height: 8),
            _MetricRow(label: 'Routes', value: '${feed.routeCount}'),
            const SizedBox(height: 8),
            _MetricRow(label: 'Stops', value: '${feed.stopCount}'),
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
                  label: const Text('Download Feed'),
                ),
                if (feed.isDownloaded)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onUpdate,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Update Feed'),
                  ),
                if (feed.isDownloaded)
                  TextButton.icon(
                    onPressed: isBusy ? null : onDelete,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    label: Text(
                      'Delete Feed',
                      style: TextStyle(color: colorScheme.error),
                    ),
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
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
