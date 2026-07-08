import '../models/gtfs_feed_info.dart';
import '../models/transit_catalog_agency.dart';
import '../models/transit_catalog_manifest.dart';
import '../models/transit_vehicle_type.dart';

/// Shipped catalog snapshot. Also written to assets/transit-catalog.json.
abstract final class TransitCatalogBundled {
  static const catalogVersion = 3;

  static const countries = <String>[
    'Canada',
    'United States',
  ];

  static const agencies = <TransitCatalogAgency>[
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
        licenseUrl:
            'https://www.gotransit.com/en/partner-with-us/software-developers',
        attributionText:
            'Contains data from GO Transit (Metrolinx) Open Data Catalogue.',
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
        licenseUrl: 'https://open.toronto.ca/open-data-licence/',
        attributionText:
            'Contains data licensed under the City of Toronto Open Data License.',
      ),
      lines: ['All routes'],
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
        downloadUrl: 'https://dozealert.app/gtfs-mirror/gtfs_yrt.zip',
        openDataPageUrl: 'https://www.yrt.ca/en/about-us/open-data.aspx',
        openDataPageLabel: 'YRT Open Data terms',
        licenseUrl: 'https://www.yrt.ca/en/about-us/open-data.aspx',
        attributionText:
            'Contains data from York Region Transit Open Data. '
            'GTFS mirrored on dozealert.app under YRT open data terms.',
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
        downloadUrl:
            'https://www.regionofwaterloo.ca/opendatadownloads/GRT_GTFS.zip',
        openDataPageUrl: 'https://www.grt.ca/about-grt/open-data/',
        openDataPageLabel: 'Open GRT Open Data Page',
        licenseUrl:
            'https://www.regionofwaterloo.ca/government-and-council/transparency-and-accountability/open-data/',
        attributionText: 'Contains data from Grand River Transit Open Data.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'guelph_transit',
      agencyName: 'Guelph Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Guelph',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'guelph_transit',
        agencyName: 'Guelph Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl:
            'https://gismaps.guelph.ca/Pages/GTFS/google_transit.zip',
        openDataPageUrl:
            'https://guelph.ca/city-government/plans-and-strategies/digital-innovation/open-data/',
        openDataPageLabel: 'Guelph Open Data',
        licenseUrl:
            'https://guelph.ca/city-government/plans-and-strategies/digital-innovation/open-data/',
        attributionText: 'Contains data from Guelph Transit Open Data.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'london_transit',
      agencyName: 'London Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'London',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'london_transit',
        agencyName: 'London Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl:
            'https://www.londontransit.ca/gtfsfeed/google_transit.zip',
        openDataPageUrl: 'https://www.londontransit.ca/open-data/',
        openDataPageLabel: 'London Transit Open Data',
        licenseUrl:
            'https://www.londontransit.ca/open-data/ltcs-open-data-terms-of-use/',
        attributionText:
            'Contains data from London Transit Commission Open Data.',
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
        downloadUrl:
            'https://www.arcgis.com/sharing/rest/content/items/a355aabd5a8c490186bdce559c9c75fb/data',
        openDataPageUrl:
            'https://geohub.brampton.ca/datasets/a355aabd5a8c490186bdce559c9c75fb',
        openDataPageLabel: 'Open Brampton Transit Data',
        licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
        attributionText:
            'Contains data from Brampton Transit Open Data (CC BY 4.0).',
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
        licenseUrl:
            'https://www.mississauga.ca/miway-transit/developer-download/',
        attributionText: 'Contains data from MiWay Open GTFS.',
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
        licenseUrl:
            'https://www.durham.ca/en/regional-government/open-data.aspx',
        attributionText: 'Contains data from Durham Region Transit Open Data.',
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
        licenseUrl:
            'https://www.gotransit.com/en/partner-with-us/software-developers',
        attributionText: 'Contains data from Milton Transit GTFS (Metrolinx host).',
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
        licenseUrl: 'https://www.oakvilletransit.ca/',
        attributionText: 'Contains data from Oakville Transit Open Data.',
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
        licenseUrl: 'https://opendata.burlington.ca/',
        attributionText: 'Contains data from Burlington Transit Open Data.',
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
        licenseUrl: 'https://opendata.hamilton.ca/GTFS-Static/',
        attributionText:
            'Contains data from Hamilton Street Railway Open Data.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'barrie_transit',
      agencyName: 'Barrie Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Barrie',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'barrie_transit',
        agencyName: 'Barrie Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl: 'http://www.myridebarrie.ca/gtfs/Google_transit.zip',
        openDataPageUrl:
            'https://www.barrie.ca/services-payments/transportation-parking/barrie-transit/barrie-gtfs',
        openDataPageLabel: 'Barrie GTFS terms',
        licenseUrl:
            'https://www.barrie.ca/services-payments/transportation-parking/barrie-transit/barrie-gtfs',
        attributionText: 'Contains data from Barrie Transit Open Data.',
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
        licenseUrl: 'https://niagaraopendata.ca/pages/open-government-license-2-0-niagara-region',
        attributionText:
            'Contains data from Niagara Region Transit Open Data.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'oc_transpo',
      agencyName: 'OC Transpo',
      country: 'Canada',
      region: 'Ontario',
      city: 'Ottawa',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'oc_transpo',
        agencyName: 'OC Transpo',
        province: 'Ontario',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.lightRail,
        ],
        downloadUrl:
            'https://oct-gtfs-emasagcnfmcgeham.z01.azurefd.net/public-access/GTFSExport.zip',
        openDataPageUrl:
            'https://www.octranspo.com/en/plan-your-trip/travel-tools/developers/',
        openDataPageLabel: 'OC Transpo developer portal',
        supportsRealtime: true,
        licenseUrl:
            'https://www.octranspo.com/en/plan-your-trip/travel-tools/developers/dev-terms',
        attributionText:
            'Contains data provided by OC Transpo, licensed under the City of '
            'Ottawa Open Government Licence.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'kingston_transit',
      agencyName: 'Kingston Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Kingston',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'kingston_transit',
        agencyName: 'Kingston Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl: 'https://api.cityofkingston.ca/gtfs/gtfs.zip',
        openDataPageUrl: 'https://www.cityofkingston.ca/transit/',
        openDataPageLabel: 'Kingston Transit',
        licenseUrl: 'https://www.cityofkingston.ca/government/open-data/',
        attributionText: 'Contains data from Kingston Transit Open Data.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'windsor_transit',
      agencyName: 'Windsor Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Windsor',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'windsor_transit',
        agencyName: 'Windsor Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl:
            'https://opendata.citywindsor.ca/Uploads/google_transit.zip',
        openDataPageUrl: 'https://opendata.citywindsor.ca/Details/218',
        openDataPageLabel: 'Windsor Open Data',
        licenseUrl:
            'http://www.citywindsor.ca/opendata/Documents/OpenDataTermsofUse.pdf',
        attributionText: 'Contains data from Windsor Transit Open Data.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'sault_ste_marie_transit',
      agencyName: 'Sault Ste. Marie Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Sault Ste. Marie',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'sault_ste_marie_transit',
        agencyName: 'Sault Ste. Marie Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl:
            'http://metrolinx.tmix.se/gtfs/gtfs-saultstemarie.zip',
        licenseUrl:
            'https://www.gotransit.com/en/partner-with-us/software-developers',
        attributionText:
            'Contains data from Sault Ste. Marie Transit GTFS (Metrolinx host).',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'thunder_bay_transit',
      agencyName: 'Thunder Bay Transit',
      country: 'Canada',
      region: 'Ontario',
      city: 'Thunder Bay',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'thunder_bay_transit',
        agencyName: 'Thunder Bay Transit',
        province: 'Ontario',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl: 'http://api.nextlift.ca/gtfs.zip',
        openDataPageUrl:
            'https://www.thunderbay.ca/en/city-services/developers---open-data.aspx',
        openDataPageLabel: 'Thunder Bay Open Data',
        licenseUrl:
            'https://www.thunderbay.ca/en/city-services/developers---open-data.aspx',
        attributionText: 'Contains data from Thunder Bay Transit Open Data.',
      ),
      lines: ['All routes'],
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

  static TransitCatalogManifest get manifest => TransitCatalogManifest(
        catalogVersion: catalogVersion,
        schemaVersion: TransitCatalogManifest.supportedSchemaVersion,
        minAppVersion: '1.1.0',
        countries: countries,
        defaultRegionByCountry: const {
          'Canada': 'Ontario',
          'United States': 'New York',
        },
        agencies: agencies,
      );
}
