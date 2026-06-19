import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_provider.dart';
import '../services/gtfs_import_service.dart';
import '../widgets/home_card.dart';

class GtfsImportScreen extends StatefulWidget {
  const GtfsImportScreen({super.key});

  @override
  State<GtfsImportScreen> createState() => _GtfsImportScreenState();
}

class _GtfsImportScreenState extends State<GtfsImportScreen> {
  List<GtfsFeedInfo> _feeds = const [];
  bool _loading = true;
  bool _importing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  Future<void> _loadFeeds() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final feeds = await context.read<GtfsImportService>().loadFeedInfos();
      if (!mounted) {
        return;
      }
      setState(() {
        _feeds = feeds;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickAndImport() async {
    final gtfsProvider = context.read<GtfsProvider>();

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

    setState(() {
      _importing = true;
      _error = null;
    });

    try {
      await gtfsProvider.importZipFeed(
        bytes: bytes,
        fileName: file.name,
      );
      await _loadFeeds();
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
      setState(() {
        _error = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import GTFS Feed'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeCardHeader(
                  icon: Icons.upload_file_outlined,
                  title: 'Import GTFS Feed',
                ),
                const SizedBox(height: 12),
                Text(
                  'Select a GTFS zip file to import transit agencies, routes, '
                  'and stops for offline use.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _importing ? null : _pickAndImport,
                    icon: _importing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.folder_open_outlined),
                    label: Text(_importing ? 'Importing…' : 'Choose GTFS Zip'),
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
                const HomeCardHeader(
                  icon: Icons.info_outline,
                  title: 'Supported Examples',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: GtfsImportService.supportedExamples
                      .map(
                        (example) => Chip(
                          label: Text(example),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          Text(
            'Imported Feeds',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_feeds.isEmpty)
            Text(
              'No GTFS feeds imported yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ..._feeds.map(_FeedInfoCard.new),
        ],
      ),
    );
  }
}

class _FeedInfoCard extends StatelessWidget {
  const _FeedInfoCard(this.feed);

  final GtfsFeedInfo feed;

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
            if (feed.sourceFileName != null) ...[
              const SizedBox(height: 4),
              Text(
                feed.sourceFileName!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _FeedMetricRow(label: 'Agencies', value: '${feed.agencyCount}'),
            const SizedBox(height: 8),
            _FeedMetricRow(label: 'Routes', value: '${feed.routeCount}'),
            const SizedBox(height: 8),
            _FeedMetricRow(label: 'Stops', value: '${feed.stopCount}'),
            const SizedBox(height: 8),
            _FeedMetricRow(label: 'Last Updated', value: lastUpdated),
          ],
        ),
      ),
    );
  }
}

class _FeedMetricRow extends StatelessWidget {
  const _FeedMetricRow({
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
