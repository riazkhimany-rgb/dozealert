import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';

/// User-facing attribution strings for open-data compliance.
abstract final class TransitAttribution {
  static const bundledPrefix =
      'Bundled stop lists are convenience snapshots only — download GTFS for '
      'the latest agency data. ';

  static GtfsFeedInfo? feedForAgency(String agencyName) {
    return TransitCatalog.feedByAgencyName(agencyName);
  }

  static String textForAgency(String agencyName) {
    final feed = feedForAgency(agencyName);
    if (feed != null) {
      return feed.resolvedAttribution;
    }

    if (_bundledAgencyIds.containsKey(agencyName)) {
      return bundledPrefix + (_bundledAgencyIds[agencyName] ?? '');
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
    return _bundledAgencyIds.containsKey(agencyName);
  }

  static const _bundledAgencyIds = <String, String>{
    'GO Transit':
        'Contains data from GO Transit (Metrolinx) Open Data Catalogue.',
    'TTC':
        'Contains data licensed under the City of Toronto Open Data License.',
  };

  static const _listOnlyAttribution = <String, String>{
    'OC Transpo':
        'OC Transpo line names are listed for convenience. Schedule and stop '
        'data is subject to City of Ottawa open data terms when you import GTFS.',
    'STM Montreal':
        'STM line names are listed for convenience. Data is subject to STM '
        'open data terms when you import GTFS.',
    'Exo':
        'Exo line names are listed for convenience. Data is subject to Exo '
        'open data terms when you import GTFS.',
    'TransLink Vancouver':
        'TransLink line names are listed for convenience. Data is subject to '
        'TransLink open data terms when you import GTFS.',
    'MTA':
        'MTA line names are listed for convenience. Data is subject to MTA '
        'open data terms when you import GTFS.',
    'Amtrak':
        'Amtrak line names are listed for convenience. Data is subject to '
        'Amtrak open data terms when you import GTFS.',
  };

  static const _listOnlyLicenseUrls = <String, String>{
    'OC Transpo': 'https://open.ottawa.ca/pages/open-data-licence',
    'STM Montreal': 'https://www.stm.info/en/about/developers',
    'Exo': 'https://exo.quebec/fr/a-propos/donnees-ouvertes',
    'TransLink Vancouver':
        'https://www.translink.ca/about-us/doing-business-with-translink/app-developer-resources/gtfs/gtfs-data',
    'MTA': 'https://www.mta.info/developers/developer-data-terms',
    'Amtrak': 'https://www.amtrak.com/developer-resources',
  };
}
