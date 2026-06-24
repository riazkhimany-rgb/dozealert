import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../models/transit_catalog_agency.dart';

/// Copy and helpers for the Transit Data Licenses screen.
abstract final class TransitDataLicenses {
  static const generalNotice =
      'DozeAlert uses public GTFS schedule and stop data from transit agencies. '
      'Data is cached on your device for offline alarms and is not redistributed '
      'by DozeAlert. Each agency sets its own open data terms — review them before '
      'downloading or importing feeds.';

  static const bundledNotice =
      'GO Transit and TTC ship with bundled stop lists so alarms work before '
      'you download full GTFS. Bundled data may be older than the agency feed — '
      'download or import GTFS on Transit Data for the latest stops.';

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
