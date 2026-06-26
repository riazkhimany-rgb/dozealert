import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gtfs_feed_info.dart';
import '../models/transit_vehicle_type.dart';
import '../providers/gtfs_feed_provider.dart';
import '../utils/gtfs_feed_download_handler.dart';

class GtfsVehicleTypeDownloadPrompt extends StatelessWidget {
  const GtfsVehicleTypeDownloadPrompt({
    super.key,
    required this.transitSystem,
    required this.vehicleType,
    this.onDownloadComplete,
  });

  final String transitSystem;
  final TransitVehicleType vehicleType;
  final VoidCallback? onDownloadComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedProvider = context.watch<GtfsFeedProvider>();
    final feed = feedProvider.feedForTransitSystem(transitSystem);
    if (feed == null) {
      return const SizedBox.shrink();
    }

    final isBusy = feedProvider.isFeedBusy(feed.feedId);
    final progress = feedProvider.progressFor(feed.feedId);
    final canDownloadDirectly = feed.hasDirectDownload && !feed.isDownloaded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.directions_bus_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Download GTFS to load ${vehicleType.label.toLowerCase()} routes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feed.isDownloaded
                ? '${vehicleType.label} routes were not found in the downloaded feed. '
                    'Try updating GTFS or choose All types.'
                : 'Bundled data covers main train and subway lines only. '
                    'Download the full ${feed.agencyName} GTFS feed to pick '
                    '${vehicleType.label.toLowerCase()} route numbers.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (isBusy) ...[
            const SizedBox(height: 12),
            if (progress?.downloadFraction != null)
              LinearProgressIndicator(
                value: progress!.downloadFraction!.clamp(0, 1),
                borderRadius: BorderRadius.circular(4),
              )
            else
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
              ),
            const SizedBox(height: 8),
            Text(
              progress?.phase ?? feed.status.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: canDownloadDirectly
                  ? () => unawaited(_download(context))
                  : null,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: Text(
                canDownloadDirectly ? 'Download GTFS' : 'Use GTFS card below',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final downloaded = await GtfsFeedDownloadHandler.downloadForTransitSystem(
      context,
      transitSystem: transitSystem,
    );
    if (downloaded && context.mounted) {
      onDownloadComplete?.call();
    }
  }
}
