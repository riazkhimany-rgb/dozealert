import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../utils/transit_user_copy.dart';
import '../utils/user_facing_errors.dart';

abstract final class GtfsFeedDownloadHandler {
  static Future<bool> downloadForTransitSystem(
    BuildContext context, {
    required String transitSystem,
  }) async {
    final feedProvider = context.read<GtfsFeedProvider>();
    final feed = feedProvider.feedForTransitSystem(transitSystem);
    if (feed == null) {
      _showSnackBar(
        context,
        TransitUserCopy.noStopFeedConfigured(transitSystem),
        isError: true,
      );
      return false;
    }

    if (!feed.hasDirectDownload) {
      _showSnackBar(
        context,
        TransitUserCopy.importStopDataHint,
      );
      return false;
    }

    if (feedProvider.isFeedBusy(feed.feedId)) {
      return false;
    }

    try {
      await feedProvider.downloadFeed(feed.feedId);
      if (!context.mounted) {
        return false;
      }
      final gtfsProvider = context.read<GtfsProvider>();
      await gtfsProvider.ensureSelectedFeedLoaded();
      await gtfsProvider.notifyDataUpdated();
      if (!context.mounted) {
        return false;
      }
      _showSnackBar(
        context,
        TransitUserCopy.stopDataDownloaded(transitSystem),
      );
      return true;
    } catch (error) {
      if (!context.mounted) {
        return false;
      }
      _showSnackBar(
        context,
        TransitUserCopy.couldNotDownloadStopData(
          transitSystem,
          UserFacingErrors.from(error),
        ),
        isError: true,
      );
      return false;
    }
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.errorContainer
            : null,
      ),
    );
  }
}
