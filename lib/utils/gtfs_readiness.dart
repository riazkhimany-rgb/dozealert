import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../models/transit_preferences.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';

/// Single source of truth for whether transit stop data is usable.
abstract final class GtfsReadiness {
  static bool hasStopDataForLine(
    GtfsProvider gtfsProvider, {
    required String transitSystem,
    required String lineName,
  }) {
    if (!gtfsProvider.isInitialized) {
      return false;
    }
    return gtfsProvider.hasStopsForLine(
      transitSystem: transitSystem,
      lineName: lineName,
    );
  }

  static bool hasStopDataForPreferences(
    GtfsProvider gtfsProvider,
    TransitPreferences preferences,
  ) {
    return hasStopDataForLine(
      gtfsProvider,
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );
  }

  /// True when the user can use transit mode / pick stops for the selected agency.
  static bool isReadyForSelectedAgency(
    GtfsProvider gtfsProvider,
    TransitPreferences preferences,
  ) {
    return hasStopDataForPreferences(gtfsProvider, preferences);
  }

  static bool isSetupChecklistComplete(
    GtfsProvider gtfsProvider,
    TransitPreferences preferences,
    GtfsFeedProvider feedProvider,
  ) {
    if (isReadyForSelectedAgency(gtfsProvider, preferences)) {
      return true;
    }

    if (!feedProvider.isInitialized) {
      return false;
    }

    final feed = feedProvider.feedForTransitSystem(preferences.transitSystem);
    return feed?.status == GtfsFeedStatus.downloaded;
  }

  /// Prompt when GTFS stop data is missing for the selected agency.
  static bool shouldPromptForDownload(
    GtfsProvider gtfsProvider,
    TransitPreferences preferences,
    GtfsFeedProvider feedProvider,
  ) {
    if (isReadyForSelectedAgency(gtfsProvider, preferences)) {
      return false;
    }

    if (!feedProvider.isInitialized) {
      return true;
    }

    final feed = feedProvider.feedForTransitSystem(preferences.transitSystem);
    if (feed == null) {
      return !TransitCatalog.hasCatalogLines(preferences.transitSystem);
    }

    return feed.status != GtfsFeedStatus.downloaded;
  }
}
