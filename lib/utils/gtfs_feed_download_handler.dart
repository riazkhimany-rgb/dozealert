import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';

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
        'No GTFS feed is configured for $transitSystem.',
        isError: true,
      );
      return false;
    }

    if (!feed.hasDirectDownload) {
      _showSnackBar(
        context,
        'Download the GTFS zip from the agency open data page, then import it '
        'from Settings → Transit → Import GTFS Zip.',
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
      await context.read<GtfsProvider>().notifyDataUpdated();
      if (!context.mounted) {
        return false;
      }
      _showSnackBar(context, '$transitSystem GTFS data downloaded.');
      return true;
    } catch (error) {
      if (!context.mounted) {
        return false;
      }
      _showSnackBar(
        context,
        'Could not download $transitSystem GTFS data: $error',
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
