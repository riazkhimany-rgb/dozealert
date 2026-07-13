import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';

/// User-facing attribution strings for open-data compliance.
abstract final class TransitAttribution {
  static const bundledPrefix =
      'Download stop lists for the latest agency data. ';

  static GtfsFeedInfo? feedForAgency(String agencyName) {
    return TransitCatalog.feedByAgencyName(agencyName);
  }

  static String textForAgency(String agencyName) {
    final feed = feedForAgency(agencyName);
    if (feed != null) {
      return feed.resolvedAttribution;
    }

    return _listOnlyAttribution[agencyName] ??
        'Transit schedule and stop data for $agencyName is subject to that '
        'agency\'s open data terms when imported or downloaded.';
  }

  static String? licenseUrlForAgency(String agencyName) {
    final feed = feedForAgency(agencyName);
    if (feed?.resolvedLicenseUrl != null) {
      return feed!.resolvedLicenseUrl;
    }
    return _listOnlyLicenseUrls[agencyName];
  }

  static bool usesBundledStops(String agencyName) {
    return false;
  }

  static const _listOnlyAttribution = <String, String>{
    'MTA':
        'MTA line names are listed for convenience. Data is subject to MTA '
        'open data terms when you import stop data.',
    'Amtrak':
        'Amtrak line names are listed for convenience. Data is subject to '
        'Amtrak open data terms when you import stop data.',
  };

  static const _listOnlyLicenseUrls = <String, String>{
    'MTA': 'https://www.mta.info/developers/developer-data-terms',
    'Amtrak': 'https://www.amtrak.com/developer-resources',
  };
}
