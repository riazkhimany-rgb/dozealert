import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../models/transit_catalog_agency.dart';

/// Copy and helpers for the Transit Data Licenses screen.
abstract final class TransitDataLicenses {
  static const generalNotice =
      'DozeAlert uses public transit schedule and stop data (GTFS format) from '
      'transit agencies. Data is cached on your device for offline alarms. '
      'Where permitted, DozeAlert may host a mirror of a GTFS file on '
      'dozealert.app for in-app download; agency open data terms still apply. '
      'Review each agency\'s terms before downloading stop lists.';

  static const nonAffiliationNotice =
      'DozeAlert is not affiliated with, endorsed by, or sponsored by any '
      'transit agency. Agency names and attributions below identify open data '
      'sources only.';

  static const bundledNotice =
      'During first-run setup, DozeAlert downloads stop lists in the background for '
      'the transit you pick when a direct agency download is available. You can also '
      'download or update stop lists under Settings → Transit → Transit stops, or '
      'import a GTFS zip where an agency requires manual import.';

  static List<TransitCatalogAgency> get bundledBootstrapAgencies {
    return TransitCatalog.agenciesWithBundledStopLists;
  }

  static List<GtfsFeedInfo> get licensedFeeds {
    final feeds = List<GtfsFeedInfo>.from(TransitCatalog.gtfsFeeds)
      ..sort((a, b) => a.agencyName.compareTo(b.agencyName));
    return feeds;
  }

  static List<TransitCatalogAgency> get listedWithoutGtfsFeed {
    return TransitCatalog.agenciesListedWithoutGtfsFeed;
  }
}
