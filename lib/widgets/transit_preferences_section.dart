import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../widgets/home_card.dart';

class TransitPreferencesSection extends StatelessWidget {
  const TransitPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preferences = context.watch<TransitProvider>().preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Transit Preferences',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _TransitPreferenceCard(
            title: 'Country',
            value: preferences.country,
            options: TransitCatalog.countries,
            onChanged: (value) {
              unawaited(context.read<TransitProvider>().setCountry(value));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _TransitPreferenceCard(
            title: TransitCatalog.regionLabelForCountry(preferences.country),
            value: preferences.region,
            options: TransitCatalog.regionsForCountry(preferences.country),
            onChanged: (value) {
              unawaited(context.read<TransitProvider>().setRegion(value));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _TransitPreferenceCard(
            title: 'Transit Agency',
            value: preferences.transitSystem,
            options: TransitCatalog.agenciesForRegion(
              preferences.country,
              preferences.region,
            ),
            onChanged: (value) {
              unawaited(context.read<TransitProvider>().setTransitSystem(value));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _DefaultLinePickerCard(
            transitSystem: preferences.transitSystem,
            selectedLine: preferences.defaultLine,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _PreferredAgencyGtfsCard(
            transitSystem: preferences.transitSystem,
          ),
        ),
      ],
    );
  }
}

class _PreferredAgencyGtfsCard extends StatefulWidget {
  const _PreferredAgencyGtfsCard({
    required this.transitSystem,
  });

  final String transitSystem;

  @override
  State<_PreferredAgencyGtfsCard> createState() =>
      _PreferredAgencyGtfsCardState();
}

class _PreferredAgencyGtfsCardState extends State<_PreferredAgencyGtfsCard> {
  bool _actionInFlight = false;

  bool get _isBusy {
    final feed = context.read<GtfsFeedProvider>().feedForTransitSystem(
      widget.transitSystem,
    );
    return _actionInFlight ||
        feed?.status == GtfsFeedStatus.downloading ||
        feed?.status == GtfsFeedStatus.updating;
  }

  Future<void> _runDownload(GtfsFeedProvider feedProvider, String feedId) async {
    setState(() => _actionInFlight = true);
    try {
      await feedProvider.downloadFeed(feedId);
      if (!mounted) {
        return;
      }
      await context.read<GtfsProvider>().refreshFromCache();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.transitSystem} GTFS data downloaded.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not download ${widget.transitSystem} GTFS data: $error',
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _actionInFlight = false);
      }
    }
  }

  Future<void> _runUpdate(GtfsFeedProvider feedProvider, String feedId) async {
    setState(() => _actionInFlight = true);
    try {
      await feedProvider.updateFeed(feedId);
      if (!mounted) {
        return;
      }
      await context.read<GtfsProvider>().refreshFromCache();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.transitSystem} GTFS data updated.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update ${widget.transitSystem} GTFS data: $error',
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _actionInFlight = false);
      }
    }
  }

  Future<void> _openDataPage(GtfsFeedInfo feed) async {
    final url = feed.openDataPageUrl;
    if (url == null) {
      return;
    }

    if (feed.requiresUserAcknowledgement) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('${feed.agencyName} Open Data'),
            content: Text(
              feed.acknowledgementMessage ??
                  'Review the open data terms before downloading GTFS data.',
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
      if (confirmed != true || !mounted) {
        return;
      }
    }

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedProvider = context.watch<GtfsFeedProvider>();
    final feed = feedProvider.feedForTransitSystem(widget.transitSystem);
    final errorMessage = feed == null
        ? null
        : feedProvider.errorFor(feed.feedId) ?? feed.errorMessage;
    final isBusy = _isBusy;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GTFS Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download stop and route data for ${widget.transitSystem} to '
            'enable stop search and Transit Mode offline.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!feedProvider.isInitialized)
            const Center(child: CircularProgressIndicator())
          else if (feed == null) ...[
            Text(
              'No GTFS feed is configured for ${widget.transitSystem}. '
              'Bundled line data may still be available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            _StatusRow(
              label: 'Status',
              value: _statusLabel(feed),
            ),
            if (feed.isDownloaded) ...[
              const SizedBox(height: 8),
              _StatusRow(label: 'Stops', value: '${feed.stopCount}'),
              const SizedBox(height: 8),
              _StatusRow(label: 'Routes', value: '${feed.routeCount}'),
            ],
            if (isBusy) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                feed.status.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage,
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (feed.hasDirectDownload && !feed.isDownloaded)
                  FilledButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _runDownload(feedProvider, feed.feedId),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download GTFS'),
                  ),
                if (feed.hasDirectDownload && feed.isDownloaded)
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _runUpdate(feedProvider, feed.feedId),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Update GTFS'),
                  ),
                if (feed.hasOpenDataPage)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => _openDataPage(feed),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(feed.openDataPageLabel ?? 'Open Data Page'),
                  ),
              ],
            ),
            if (!feed.hasDirectDownload && !feed.hasOpenDataPage) ...[
              Text(
                'This agency does not provide a direct GTFS download link.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (!feed.hasDirectDownload) ...[
              const SizedBox(height: 8),
              Text(
                'Download the zip from the open data page, then import it from '
                'Settings → Transit → Import GTFS Zip.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _statusLabel(GtfsFeedInfo feed) {
    if (feed.isDownloaded) {
      return 'Downloaded';
    }
    return feed.status.label;
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
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

class _DefaultLinePickerCard extends StatelessWidget {
  const _DefaultLinePickerCard({
    required this.transitSystem,
    required this.selectedLine,
  });

  final String transitSystem;
  final String selectedLine;

  static const _searchThreshold = 8;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gtfsProvider = context.watch<GtfsProvider>();
    final lines = gtfsProvider.availableLinesForSelectedAgency();
    final options = lines.isEmpty
        ? TransitCatalog.linesForSystem(transitSystem)
        : lines;
    final resolvedValue = options.contains(selectedLine)
        ? selectedLine
        : options.first;
    final needsGtfsDownload = options.length == 1 &&
        options.single == TransitCatalog.allRoutesLine &&
        !gtfsProvider.hasStopsForSelectedAgency();
    final useSearch = options.length > _searchThreshold;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Line',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (useSearch)
            _SearchableLineButton(
              value: resolvedValue,
              options: options,
              onChanged: (value) {
                unawaited(context.read<TransitProvider>().setDefaultLine(value));
              },
            )
          else
            InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: resolvedValue,
                  items: options
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (selected) {
                    if (selected != null) {
                      unawaited(
                        context.read<TransitProvider>().setDefaultLine(selected),
                      );
                    }
                  },
                ),
              ),
            ),
          if (needsGtfsDownload) ...[
            const SizedBox(height: 12),
            Text(
              'Download GTFS data below to load routes for $transitSystem.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (gtfsProvider.usesDynamicLinesForSelectedAgency &&
              gtfsProvider.hasStopsForSelectedAgency()) ...[
            const SizedBox(height: 12),
            Text(
              '${options.length} routes loaded from GTFS.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchableLineButton extends StatelessWidget {
  const _SearchableLineButton({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _SearchableLineSheet(
          options: options,
          selected: value,
        );
      },
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () => _openPicker(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Icon(Icons.search),
        ],
      ),
    );
  }
}

class _SearchableLineSheet extends StatefulWidget {
  const _SearchableLineSheet({
    required this.options,
    required this.selected,
  });

  final List<String> options;
  final String selected;

  @override
  State<_SearchableLineSheet> createState() => _SearchableLineSheetState();
}

class _SearchableLineSheetState extends State<_SearchableLineSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = normalizedQuery.isEmpty
        ? widget.options
        : widget.options
            .where((line) => line.toLowerCase().contains(normalizedQuery))
            .toList(growable: false);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Choose Route',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search routes…',
              leading: const Icon(Icons.search),
              trailing: _query.isEmpty
                  ? null
                  : [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                    ],
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No routes match "$_query".',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final line = filtered[index];
                      final isSelected = line == widget.selected;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(line),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(line),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransitPreferenceCard extends StatelessWidget {
  const _TransitPreferenceCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: options.contains(value) ? value : options.first,
                items: options
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                onChanged: (selected) {
                  if (selected != null) {
                    onChanged(selected);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
