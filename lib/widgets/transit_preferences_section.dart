import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../models/transit_vehicle_type.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../utils/external_link_launcher.dart';
import '../utils/transit_line_picker_utils.dart';
import '../utils/transit_user_copy.dart';
import '../utils/user_facing_errors.dart';
import '../widgets/home_card.dart';
import '../widgets/gtfs_vehicle_type_download_prompt.dart';
import '../widgets/gtfs_feed_progress_indicator.dart';
import '../widgets/searchable_line_picker.dart';
import '../widgets/transit_attribution_notice.dart';
import '../widgets/vehicle_type_filter_chips.dart';

class TransitPreferencesSection extends StatelessWidget {
  const TransitPreferencesSection({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preferences = context.watch<TransitProvider>().preferences;
    final headerPadding = compact
        ? const EdgeInsets.fromLTRB(0, 0, 0, 8)
        : const EdgeInsets.fromLTRB(24, 16, 24, 8);
    final cardPadding = compact
        ? const EdgeInsets.fromLTRB(0, 0, 0, 12)
        : const EdgeInsets.fromLTRB(20, 0, 20, 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Padding(
            padding: headerPadding,
            child: Text(
              TransitUserCopy.transitAndLine,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(
          padding: cardPadding,
          child: _PreferredAgencySetupCard(
            key: ValueKey(preferences.transitSystem),
            includeLocationFields: !compact,
          ),
        ),
        if (compact)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Advanced options',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Stop list download'),
            children: [
              _PreferredAgencyGtfsCard(
                transitSystem: preferences.transitSystem,
              ),
            ],
          )
        else
          Padding(
            padding: cardPadding,
            child: _PreferredAgencyGtfsCard(
              transitSystem: preferences.transitSystem,
            ),
          ),
        Padding(
          padding: cardPadding,
          child: TransitAttributionNotice(
            agencyName: preferences.transitSystem,
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _PreferredAgencySetupCard extends StatefulWidget {
  const _PreferredAgencySetupCard({
    super.key,
    required this.includeLocationFields,
  });

  final bool includeLocationFields;

  @override
  State<_PreferredAgencySetupCard> createState() =>
      _PreferredAgencySetupCardState();
}

class _PreferredAgencySetupCardState extends State<_PreferredAgencySetupCard> {
  TransitVehicleType? _vehicleTypeFilter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preferences = context.watch<TransitProvider>().preferences;
    final gtfsProvider = context.watch<GtfsProvider>();
    final vehicleTypes = gtfsProvider.availableVehicleTypesForSelectedAgency();
    final lineOptions = gtfsProvider.availableLineOptionsForSelectedAgency(
      vehicleType: _vehicleTypeFilter,
    );
    final lineNames = lineOptions.map((option) => option.lineName).toList();
    final savedLineInList = lineNames.contains(preferences.defaultLine);
    final hasVehicleFilter = _vehicleTypeFilter != null;
    // Display value for the dropdown; must be one of [lineNames] so the
    // DropdownButton does not assert.
    final resolvedLine = savedLineInList
        ? preferences.defaultLine
        : (lineNames.isNotEmpty ? lineNames.first : preferences.defaultLine);
    final needsGtfsDownload = lineNames.length == 1 &&
        lineNames.single == TransitCatalog.allRoutesLine &&
        !gtfsProvider.hasStopsForSelectedAgency();
    final showGtfsPrompt = _vehicleTypeFilter != null &&
        lineOptions.isEmpty &&
        vehicleTypes.contains(_vehicleTypeFilter);
    final useSearch = TransitLinePickerUtils.shouldUseSearchableLinePicker(
      lineOptions: lineOptions,
      vehicleType: _vehicleTypeFilter,
    );

    // Only repair the *saved* line when it genuinely no longer maps to any
    // route for this agency. A vehicle-type filter is a transient view, so it
    // must never overwrite the user's stored line (which previously snapped the
    // selection to the first route, e.g. "11").
    final lineNeedsRepair = !hasVehicleFilter &&
        lineNames.isNotEmpty &&
        !savedLineInList &&
        !gtfsProvider.selectedAgencyHasRouteForLine(preferences.defaultLine);
    if (lineNeedsRepair) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(
          context.read<TransitProvider>().setDefaultLine(lineNames.first),
        );
      });
    }

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.includeLocationFields
                ? TransitUserCopy.transitAndLine
                : TransitUserCopy.linePreferences,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.includeLocationFields) ...[
            _InlineDropdown(
              label: 'Country',
              value: preferences.country,
              options: TransitCatalog.countries,
              onChanged: (value) {
                unawaited(context.read<TransitProvider>().setCountry(value));
              },
            ),
            const SizedBox(height: 12),
            _InlineDropdown(
              label: TransitCatalog.regionLabelForCountry(preferences.country),
              value: preferences.region,
              options: TransitCatalog.regionsForCountry(preferences.country),
              onChanged: (value) {
                unawaited(context.read<TransitProvider>().setRegion(value));
              },
            ),
            const SizedBox(height: 12),
            _InlineDropdown(
              label: TransitUserCopy.transitLabel,
              value: preferences.transitSystem,
              options: TransitCatalog.agenciesForRegion(
                preferences.country,
                preferences.region,
              ),
              onChanged: (value) {
                unawaited(
                  context.read<TransitProvider>().setTransitSystem(value),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          if (vehicleTypes.isNotEmpty) ...[
            Text(
              'Vehicle type',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            VehicleTypeFilterChips(
              vehicleTypes: vehicleTypes,
              selected: _vehicleTypeFilter,
              onSelected: (type) {
                setState(() => _vehicleTypeFilter = type);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (showGtfsPrompt && _vehicleTypeFilter != null) ...[
            GtfsVehicleTypeDownloadPrompt(
              transitSystem: preferences.transitSystem,
              vehicleType: _vehicleTypeFilter!,
              onDownloadComplete: () => setState(() {}),
            ),
            const SizedBox(height: 12),
          ],
          if (lineOptions.isEmpty)
            Text(
              _vehicleTypeFilter == null
                  ? TransitUserCopy.downloadStopsToLoadRoutes(
                      preferences.transitSystem,
                    )
                  : 'No ${_vehicleTypeFilter!.label.toLowerCase()} routes loaded. '
                      'Try All types or download stop data below.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else if (useSearch) ...[
            Text(
              TransitUserCopy.lineLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SearchableLinePicker(
              value: resolvedLine,
              options: lineOptions,
              hintText: 'Search route number or name…',
              onChanged: (value) {
                unawaited(context.read<TransitProvider>().setDefaultLine(value));
              },
            ),
          ] else
            _InlineDropdown(
              label: TransitUserCopy.lineLabel,
              value: resolvedLine,
              options: lineNames,
              onChanged: (value) {
                unawaited(context.read<TransitProvider>().setDefaultLine(value));
              },
            ),
          if (needsGtfsDownload) ...[
            const SizedBox(height: 12),
            Text(
              TransitUserCopy.downloadStopsToLoadAllRoutes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (gtfsProvider.usesDynamicLinesForSelectedAgency &&
              gtfsProvider.hasStopsForSelectedAgency()) ...[
            const SizedBox(height: 12),
            Text(
              TransitUserCopy.routesLoadedCount(
                lineOptions.length,
                vehicleFilter: _vehicleTypeFilter?.label,
              ),
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

class _InlineDropdown extends StatelessWidget {
  const _InlineDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = options.contains(value) ? value : options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
                  onChanged(selected);
                }
              },
            ),
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

  Future<void> _runDownload(GtfsFeedProvider feedProvider, String feedId) async {
    setState(() => _actionInFlight = true);
    try {
      await feedProvider.downloadFeed(feedId);
      if (!mounted) {
        return;
      }
      await context.read<GtfsProvider>().notifyDataUpdated();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TransitUserCopy.stopDataDownloaded(widget.transitSystem),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TransitUserCopy.couldNotDownloadStopData(
              widget.transitSystem,
              UserFacingErrors.from(error),
            ),
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
      await context.read<GtfsProvider>().notifyDataUpdated();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TransitUserCopy.stopDataUpdated(widget.transitSystem),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            TransitUserCopy.couldNotUpdateStopData(
              widget.transitSystem,
              UserFacingErrors.from(error),
            ),
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
                  'Review the open data terms before downloading stop data.',
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

    await ExternalLinkLauncher.openOrSnackBar(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedProvider = context.watch<GtfsFeedProvider>();
    final feed = feedProvider.feedForTransitSystem(widget.transitSystem);
    final errorMessage = feed == null
        ? null
        : feedProvider.errorFor(feed.feedId) ?? feed.errorMessage;
    final isBusy = feed == null
        ? _actionInFlight
        : _actionInFlight || feedProvider.isFeedBusy(feed.feedId);
    final progress =
        feed == null ? null : feedProvider.progressFor(feed.feedId);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TransitUserCopy.stopDataSectionTitle,
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
            TransitUserCopy.noStopFeedConfigured(widget.transitSystem),
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
              GtfsFeedProgressIndicator(
                progress: progress ??
                    GtfsFeedProgress(
                      phase: feed.status.label,
                      overallFraction: 0.05,
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
                    label: Text(TransitUserCopy.downloadStops),
                  ),
                if (feed.hasDirectDownload && feed.isDownloaded)
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _runUpdate(feedProvider, feed.feedId),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(TransitUserCopy.updateStops),
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
                TransitUserCopy.noDirectDownloadLink,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (!feed.hasDirectDownload) ...[
              const SizedBox(height: 8),
              Text(
                TransitUserCopy.importStopDataHint,
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
