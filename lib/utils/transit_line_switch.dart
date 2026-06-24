import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/default_gtfs_feeds.dart';
import '../models/favorite_transit_line.dart';
import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../providers/transit_provider.dart';
import '../widgets/stop_picker_sheet.dart';
import 'gtfs_readiness.dart';

enum TransitLineSwitchResult {
  alreadySelected,
  switched,
  downloading,
  failed,
}

abstract final class TransitLineSwitch {
  static Future<TransitLineSwitchResult> apply(
    BuildContext context,
    FavoriteTransitLine favorite,
  ) async {
    final transitProvider = context.read<TransitProvider>();
    final gtfsProvider = context.read<GtfsProvider>();
    final gtfsFeedProvider = context.read<GtfsFeedProvider>();
    final transitModeProvider = context.read<TransitModeProvider>();

    if (favorite.matches(transitProvider.preferences)) {
      return TransitLineSwitchResult.alreadySelected;
    }

    await transitProvider.applyTransitSelection(
      country: favorite.country,
      region: favorite.region,
      transitSystem: favorite.transitSystem,
      defaultLine: favorite.lineName,
    );

    await gtfsProvider.syncTransitModeRouteForSelectedLine();

    if (GtfsReadiness.hasStopDataForLine(
      gtfsProvider,
      transitSystem: favorite.transitSystem,
      lineName: favorite.lineName,
    )) {
      transitModeProvider.refreshFromSettings();
      return TransitLineSwitchResult.switched;
    }

    final feedSeed = DefaultGtfsFeeds.byAgencyName(favorite.transitSystem);
    if (feedSeed == null) {
      return TransitLineSwitchResult.failed;
    }

    final feed = gtfsFeedProvider.feedById(feedSeed.feedId);
    if (feed?.status == GtfsFeedStatus.downloaded) {
      await gtfsProvider.refreshFromCache();
      transitModeProvider.refreshFromSettings();
      return TransitLineSwitchResult.switched;
    }

    gtfsFeedProvider.preloadFeedIfNeeded(
      feedSeed.feedId,
      onComplete: () async {
        await gtfsProvider.refreshFromCache();
        await gtfsProvider.syncTransitModeRouteForSelectedLine();
        transitModeProvider.refreshFromSettings();
      },
    );

    return TransitLineSwitchResult.downloading;
  }

  /// Switches line, then opens the stop picker when stop data is available.
  static Future<void> applyAndPickStop(
    BuildContext context,
    FavoriteTransitLine favorite, {
    bool popLinePickerFirst = false,
  }) async {
    final result = await apply(context, favorite);
    if (!context.mounted) {
      return;
    }

    if (popLinePickerFirst) {
      Navigator.of(context).pop();
    }

    showResultSnackBar(context, result, favorite);

    if (result == TransitLineSwitchResult.failed) {
      return;
    }

    final gtfsProvider = context.read<GtfsProvider>();
    await gtfsProvider.syncTransitModeRouteForSelectedLine();
    if (!context.mounted) {
      return;
    }

    if (gtfsProvider.canShowStopPicker()) {
      await StopPickerSheet.show(context);
      return;
    }

    if (result != TransitLineSwitchResult.downloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stop list not ready for ${favorite.transitSystem}. '
            'Open Transit Data to download GTFS.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static void showResultSnackBar(
    BuildContext context,
    TransitLineSwitchResult result,
    FavoriteTransitLine favorite,
  ) {
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case TransitLineSwitchResult.alreadySelected:
        return;
      case TransitLineSwitchResult.switched:
        messenger.showSnackBar(
          SnackBar(
            content: Text('Switched to ${favorite.label}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case TransitLineSwitchResult.downloading:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Downloading ${favorite.transitSystem} data in the background…',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      case TransitLineSwitchResult.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Could not switch to ${favorite.label}. Open Transit Data to download.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}
