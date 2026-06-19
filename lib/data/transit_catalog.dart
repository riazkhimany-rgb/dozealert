import '../models/gtfs_feed_info.dart';
import '../models/transit_agency.dart';
import '../models/transit_catalog_agency.dart';
import '../models/transit_preferences.dart';
import '../models/transit_vehicle_type.dart';

/// Unified Canada / US transit catalog and GTFS feed registry.
abstract final class TransitCatalog {
  static const countries = <String>[
    'Canada',
    'United States',
  ];

  static const _agencies = <TransitCatalogAgency>[
    TransitCatalogAgency(
      agencyId: 'go_transit',
      agencyName: 'GO Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Toronto',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'go_transit',
        agencyName: 'GO Transit',
        province: 'Ontario',
        vehicleTypes: [
          TransitVehicleType.train,
          TransitVehicleType.bus,
        ],
        downloadUrl:
            'https://assets.metrolinx.com/raw/upload/v1683228856/Documents/Metrolinx/Open%20Data/GO-GTFS.zip',
        supportsRealtime: true,
      ),
      lines: [
        'Lakeshore West',
        'Lakeshore East',
        'Milton',
        'Kitchener',
        'Barrie',
        'Stouffville',
        'Richmond Hill',
      ],
    ),
    TransitCatalogAgency(
      agencyId: 'ttc',
      agencyName: 'TTC',
      country: 'Canada',
      region: 'Ontario',
      city: 'Toronto',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'ttc',
        agencyName: 'TTC',
        province: 'Ontario',
        vehicleTypes: [
          TransitVehicleType.subway,
          TransitVehicleType.streetcar,
          TransitVehicleType.bus,
        ],
        downloadUrl:
            'https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/7795b45e-e65a-4465-81fc-c36b9dfff169/resource/cfb6b2b8-6191-41e3-bda1-b175c51148cb/download/TTC%20Routes%20and%20Schedules%20Data.zip',
        supportsRealtime: true,
      ),
      lines: ['Line 1', 'Line 2', 'Line 4'],
    ),
    TransitCatalogAgency(
      agencyId: 'yrt',
      agencyName: 'York Region Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'York Region',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'yrt',
        agencyName: 'York Region Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        openDataPageUrl: 'https://www.yrt.ca/en/about-us/open-data.aspx',
        openDataPageLabel: 'Open YRT Download Page',
        requiresUserAcknowledgement: true,
        acknowledgementMessage:
            'YRT open data requires you to review their terms on the YRT website '
            'before downloading the GTFS feed. Import the downloaded zip using '
            'Import GTFS Zip on this screen.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'grt',
      agencyName: 'Grand River Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Waterloo Region',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'grt',
        agencyName: 'Grand River Transit',
        province: 'Ontario',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.lightRail,
        ],
        openDataPageUrl: 'https://www.grt.ca/en/about-grt/open-data.aspx',
        openDataPageLabel: 'Open GRT Open Data Page',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'brampton_transit',
      agencyName: 'Brampton Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Brampton',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'brampton_transit',
        agencyName: 'Brampton Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        openDataPageUrl:
            'https://geohub.brampton.ca/datasets/a355aabd5a8c490186bdce559c9c75fb',
        openDataPageLabel: 'Open Brampton Transit Data',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'miway',
      agencyName: 'MiWay',
      country: 'Canada',
      region: 'Ontario',
      city: 'Mississauga',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'miway',
        agencyName: 'MiWay',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl: 'https://www.miapp.ca/GTFS/google_transit.zip',
        openDataPageUrl:
            'https://www.mississauga.ca/miway-transit/developer-download/',
        openDataPageLabel: 'MiWay Developer Download',
        supportsRealtime: true,
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'durham_region_transit',
      agencyName: 'Durham Region Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Durham Region',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'durham_region_transit',
        agencyName: 'Durham Region Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl:
            'https://maps.durham.ca/OpenDataGTFS/GTFS_Durham_TXT.zip',
        openDataPageUrl:
            'https://www.durham.ca/en/regional-government/open-data.aspx',
        openDataPageLabel: 'Durham Region Open Data',
        supportsRealtime: true,
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'milton_transit',
      agencyName: 'Milton Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Milton',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'milton_transit',
        agencyName: 'Milton Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl: 'http://metrolinx.tmix.se/gtfs/gtfs-milton.zip',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'oakville_transit',
      agencyName: 'Oakville Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Oakville',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'oakville_transit',
        agencyName: 'Oakville Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl:
            'https://www.arcgis.com/sharing/rest/content/items/d78a1c1ad6a940009de8b68839a8f606/data',
        openDataPageUrl: 'https://www.oakvilletransit.ca/',
        openDataPageLabel: 'Oakville Transit',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'burlington_transit',
      agencyName: 'Burlington Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Burlington',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'burlington_transit',
        agencyName: 'Burlington Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl: 'https://opendata.burlington.ca/gtfs-rt/GTFS_Data.zip',
        openDataPageUrl: 'https://www.burlington.ca/en/services-for-you/transit',
        openDataPageLabel: 'Burlington Transit Open Data',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'hsr',
      agencyName: 'Hamilton Street Railway',
      country: 'Canada',
      region: 'Ontario',
      city: 'Hamilton',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'hsr',
        agencyName: 'Hamilton Street Railway',
        province: 'Ontario',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.lightRail,
        ],
        downloadUrl:
            'https://opendata.hamilton.ca/GTFS-Static/google_transit.zip',
        openDataPageUrl: 'https://opendata.hamilton.ca/GTFS-Static/',
        openDataPageLabel: 'Hamilton Open Data GTFS',
        supportsRealtime: true,
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'niagara_region_transit',
      agencyName: 'Niagara Region Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Niagara Region',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'niagara_region_transit',
        agencyName: 'Niagara Region Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl: 'http://68.71.24.110/gtfs/GTFSExport.zip',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'oc_transpo',
      agencyName: 'OC Transpo',
      country: 'Canada',
      region: 'Ontario',
      city: 'Ottawa',
      lines: ['Line 1', 'Line 2'],
    ),
    TransitCatalogAgency(
      agencyId: 'stm_montreal',
      agencyName: 'STM Montreal',
      country: 'Canada',
      region: 'Quebec',
      city: 'Montreal',
      lines: ['Line 1', 'Line 2', 'Line 4'],
    ),
    TransitCatalogAgency(
      agencyId: 'exo_montreal',
      agencyName: 'Exo',
      country: 'Canada',
      region: 'Quebec',
      city: 'Montreal',
      lines: ['Mont-Saint-Hilaire', 'Candiac'],
    ),
    TransitCatalogAgency(
      agencyId: 'translink_vancouver',
      agencyName: 'TransLink Vancouver',
      country: 'Canada',
      region: 'British Columbia',
      city: 'Vancouver',
      lines: ['Expo Line', 'Millennium Line', 'Canada Line'],
    ),
    TransitCatalogAgency(
      agencyId: 'mta',
      agencyName: 'MTA',
      country: 'United States',
      region: 'New York',
      city: 'New York City',
      lines: ['Hudson', 'Harlem'],
    ),
    TransitCatalogAgency(
      agencyId: 'amtrak',
      agencyName: 'Amtrak',
      country: 'United States',
      region: 'Multi-State',
      city: 'National',
      lines: ['Northeast Regional', 'Acela'],
    ),
  ];

  static const _defaultRegionByCountry = <String, String>{
    'Canada': 'Ontario',
    'United States': 'New York',
  };

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
        : defaultLineForSystem(transitSystem);

    return TransitPreferences(
      country: country,
      region: region,
      transitSystem: transitSystem,
      defaultLine: defaultLine,
    );
  }
}
