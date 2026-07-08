import 'dart:ui';

import '../models/gtfs_feed_info.dart';
import '../models/transit_agency.dart';
import '../models/transit_catalog_agency.dart';
import '../models/transit_preferences.dart';
import 'transit_catalog_registry.dart';

/// Unified Canada / US transit catalog and GTFS feed registry.
///
/// Data is loaded from a versioned JSON manifest (bundled asset + optional
/// remote update). See [TransitCatalogStore].
abstract final class TransitCatalog {
  /// Placeholder line for bus agencies until GTFS routes are loaded.
  static const allRoutesLine = 'All routes';

  static List<TransitCatalogAgency> get _agencies =>
      TransitCatalogRegistry.agencies;

  static List<String> get countries => TransitCatalogRegistry.countries;

  static Map<String, String> get _defaultRegionByCountry =>
      TransitCatalogRegistry.defaultRegionByCountry;

  static int get catalogVersion => TransitCatalogRegistry.catalogVersion;

  static String regionLabelForCountry(String country) {
    return country == 'United States' ? 'State' : 'Province / Territory';
  }

  static List<String> regionsForCountry(String country) {
    final regions = <String>{};
    for (final agency in _agencies) {
      if (agency.country == country) {
        regions.add(agency.region);
      }
    }
    return regions.toList()..sort();
  }

  static List<String> agenciesForRegion(String country, String region) {
    return _agencies
        .where((agency) => agency.country == country && agency.region == region)
        .map((agency) => agency.agencyName)
        .toList(growable: false);
  }

  static List<String> linesForSystem(String transitSystem) {
    for (final agency in _agencies) {
      if (agency.agencyName == transitSystem) {
        return agency.lines;
      }
    }
    return linesForSystem(defaultAgencyForRegion('Canada', 'Ontario'));
  }

  /// Agencies with curated line lists (GO, TTC) vs GTFS-derived routes (bus).
  static bool hasCatalogLines(String transitSystem) {
    final lines = linesForSystem(transitSystem);
    return lines.length > 1 ||
        (lines.length == 1 && lines.single != allRoutesLine);
  }

  static String defaultRegionForCountry(String country) {
    final preferred = _defaultRegionByCountry[country];
    if (preferred != null && regionsForCountry(country).contains(preferred)) {
      return preferred;
    }
    return regionsForCountry(country).first;
  }

  static String defaultAgencyForRegion(String country, String region) {
    return agenciesForRegion(country, region).first;
  }

  static String defaultLineForSystem(String transitSystem) {
    final lines = linesForSystem(transitSystem);
    return lines.first;
  }

  static List<GtfsFeedInfo> get gtfsFeeds {
    return _agencies
        .where((agency) => agency.gtfsFeed != null)
        .map((agency) => agency.gtfsFeed!)
        .toList(growable: false);
  }

  /// Agencies that previously shipped bundled stop JSON (now use GTFS download).
  static List<TransitCatalogAgency> get agenciesWithBundledStopLists {
    return const [];
  }

  /// Agencies selectable in the app but without a catalog GTFS feed entry.
  static List<TransitCatalogAgency> get agenciesListedWithoutGtfsFeed {
    return _agencies
        .where((agency) => agency.gtfsFeed == null && agency.lines.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.agencyName.compareTo(b.agencyName));
  }

  static List<GtfsFeedInfo> gtfsFeedsForRegion(String country, String region) {
    return _agencies
        .where(
          (agency) =>
              agency.country == country &&
              agency.region == region &&
              agency.gtfsFeed != null,
        )
        .map((agency) => agency.gtfsFeed!)
        .toList(growable: false);
  }

  static List<TransitAgency> get seedAgencies {
    return _agencies
        .map(
          (agency) => TransitAgency(
            agencyId: agency.agencyId,
            agencyName: agency.agencyName,
            country: agency.country,
            city: agency.city,
            supportsRealtime: agency.gtfsFeed?.supportsRealtime ?? false,
          ),
        )
        .toList(growable: false);
  }

  static TransitCatalogAgency? agencyByName(String agencyName) {
    final normalized = agencyName.trim().toLowerCase();
    for (final agency in _agencies) {
      if (agency.agencyName.toLowerCase() == normalized) {
        return agency;
      }
    }
    return null;
  }

  static GtfsFeedInfo? feedById(String feedId) {
    for (final agency in _agencies) {
      if (agency.gtfsFeed?.feedId == feedId) {
        return agency.gtfsFeed;
      }
    }
    return null;
  }

  static GtfsFeedInfo? feedByAgencyName(String agencyName) {
    return agencyByName(agencyName)?.gtfsFeed;
  }

  static bool isValidCountry(String country) {
    return countries.contains(country);
  }

  static bool isValidRegionForCountry(String country, String region) {
    return regionsForCountry(country).contains(region);
  }

  static bool isValidAgencyForRegion(
    String country,
    String region,
    String transitSystem,
  ) {
    return agenciesForRegion(country, region).contains(transitSystem);
  }

  static bool isValidLineForSystem(String transitSystem, String line) {
    return linesForSystem(transitSystem).contains(line);
  }

  /// Picks a sensible default country/region/agency from the device locale.
  static TransitPreferences preferencesForLocale(Locale locale) {
    final countryCode = locale.countryCode?.toUpperCase();
    if (countryCode == 'US') {
      const country = 'United States';
      final region = defaultRegionForCountry(country);
      final transitSystem = defaultAgencyForRegion(country, region);
      return normalize(
        TransitPreferences(
          country: country,
          region: region,
          transitSystem: transitSystem,
          defaultLine: defaultLineForSystem(transitSystem),
        ),
      );
    }

    return normalize(TransitPreferences.defaults);
  }

  static TransitPreferences normalize(TransitPreferences preferences) {
    var country = isValidCountry(preferences.country)
        ? preferences.country
        : TransitPreferences.defaults.country;
    var region = isValidRegionForCountry(country, preferences.region)
        ? preferences.region
        : defaultRegionForCountry(country);
    var transitSystem = isValidAgencyForRegion(
      country,
      region,
      preferences.transitSystem,
    )
        ? preferences.transitSystem
        : defaultAgencyForRegion(country, region);
    var defaultLine = isValidLineForSystem(transitSystem, preferences.defaultLine)
        ? preferences.defaultLine
        : preferences.defaultLine.trim().isEmpty
            ? defaultLineForSystem(transitSystem)
            : preferences.defaultLine;

    return TransitPreferences(
      country: country,
      region: region,
      transitSystem: transitSystem,
      defaultLine: defaultLine,
    );
  }
}
