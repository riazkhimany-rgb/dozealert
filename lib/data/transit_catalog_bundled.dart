import '../models/gtfs_feed_info.dart';
import '../models/transit_catalog_agency.dart';
import '../models/transit_catalog_manifest.dart';
import '../models/transit_vehicle_type.dart';

/// Shipped catalog snapshot. Also written to assets/transit-catalog.json.
abstract final class TransitCatalogBundled {
  static const catalogVersion = 4;

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
      gtfsFeed: GtfsFeedInfo(
        feedId: 'mta',
        agencyName: 'MTA',
        province: 'New York',
        vehicleTypes: [
          TransitVehicleType.subway,
          TransitVehicleType.bus,
          TransitVehicleType.train,
        ],
        downloadUrl:
            'https://rrgtfsfeeds.s3.amazonaws.com/gtfs_supplemented.zip',
        openDataPageUrl: 'https://www.mta.info/developers',
        openDataPageLabel: 'MTA Developer Resources',
        supportsRealtime: true,
        licenseUrl: 'https://www.mta.info/developers/terms-and-conditions',
        attributionText:
            'Contains data from MTA New York City Transit under the MTA '
            'Developer Terms and Conditions.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'cta',
      agencyName: 'CTA',
      country: 'United States',
      region: 'Illinois',
      city: 'Chicago',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'cta',
        agencyName: 'CTA',
        province: 'Illinois',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.subway,
        ],
        downloadUrl:
            'https://www.transitchicago.com/downloads/sch_data/google_transit.zip',
        openDataPageUrl: 'https://www.transitchicago.com/developers/gtfs/',
        openDataPageLabel: 'CTA GTFS',
        licenseUrl:
            'http://www.transitchicago.com/downloads/sch_data/developers_license_agreement.htm',
        attributionText:
            'Contains data from the Chicago Transit Authority (CTA).',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'mbta',
      agencyName: 'MBTA',
      country: 'United States',
      region: 'Massachusetts',
      city: 'Boston',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'mbta',
        agencyName: 'MBTA',
        province: 'Massachusetts',
        vehicleTypes: [
          TransitVehicleType.train,
          TransitVehicleType.bus,
          TransitVehicleType.subway,
          TransitVehicleType.lightRail,
        ],
        downloadUrl: 'https://cdn.mbta.com/MBTA_GTFS.zip',
        openDataPageUrl: 'https://www.mbta.com/developers',
        openDataPageLabel: 'MBTA Developers',
        supportsRealtime: true,
        licenseUrl:
            'https://www.mass.gov/files/documents/2017/10/27/develop_license_agree_0.pdf',
        attributionText:
            'Contains data from the Massachusetts Bay Transportation Authority '
            '(MBTA) under the MassDOT Developers License Agreement.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'septa',
      agencyName: 'SEPTA',
      country: 'United States',
      region: 'Pennsylvania',
      city: 'Philadelphia',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'septa',
        agencyName: 'SEPTA',
        province: 'Pennsylvania',
        vehicleTypes: [
          TransitVehicleType.train,
          TransitVehicleType.bus,
          TransitVehicleType.subway,
          TransitVehicleType.lightRail,
        ],
        downloadUrl: 'https://www3.septa.org/developer/gtfs_public.zip',
        openDataPageUrl: 'https://www3.septa.org/developer/',
        openDataPageLabel: 'SEPTA Developer Download',
        supportsRealtime: true,
        licenseUrl: 'https://www3.septa.org/developer/',
        attributionText: 'Contains data from SEPTA under the SEPTA License Agreement.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'nj_transit',
      agencyName: 'NJ Transit',
      country: 'United States',
      region: 'New Jersey',
      city: 'New Jersey',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'nj_transit',
        agencyName: 'NJ Transit',
        province: 'New Jersey',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.lightRail,
        ],
        downloadUrl: 'https://www.njtransit.com/bus_data.zip',
        openDataPageUrl: 'https://developer.njtransit.com/',
        openDataPageLabel: 'NJ Transit Developer Portal',
        licenseUrl: 'https://developer.njtransit.com/terms/',
        attributionText:
            'Contains data from NJ Transit under the NJ Transit Developer Terms '
            'and Conditions.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'nj_transit_rail',
      agencyName: 'NJ Transit Rail',
      country: 'United States',
      region: 'New Jersey',
      city: 'New Jersey',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'nj_transit_rail',
        agencyName: 'NJ Transit Rail',
        province: 'New Jersey',
        vehicleTypes: [TransitVehicleType.train],
        downloadUrl: 'https://www.njtransit.com/rail_data.zip',
        openDataPageUrl: 'https://developer.njtransit.com/',
        openDataPageLabel: 'NJ Transit Developer Portal',
        licenseUrl: 'https://developer.njtransit.com/terms/',
        attributionText:
            'Contains data from NJ Transit under the NJ Transit Developer Terms '
            'and Conditions.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'la_metro',
      agencyName: 'LA Metro',
      country: 'United States',
      region: 'California',
      city: 'Los Angeles',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'la_metro',
        agencyName: 'LA Metro',
        province: 'California',
        vehicleTypes: [TransitVehicleType.bus],
        downloadUrl:
            'https://gitlab.com/LACMTA/gtfs_bus/raw/master/gtfs_bus.zip',
        openDataPageUrl: 'https://developer.metro.net/gtfs-schedule-data/',
        openDataPageLabel: 'Metro GTFS Schedule Data',
        licenseUrl: 'https://developer.metro.net/',
        attributionText: 'Contains data from LA Metro (LACMTA) bus service.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'la_metro_rail',
      agencyName: 'LA Metro Rail',
      country: 'United States',
      region: 'California',
      city: 'Los Angeles',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'la_metro_rail',
        agencyName: 'LA Metro Rail',
        province: 'California',
        vehicleTypes: [
          TransitVehicleType.train,
          TransitVehicleType.lightRail,
        ],
        downloadUrl:
            'https://gitlab.com/LACMTA/gtfs_rail/raw/master/gtfs_rail.zip',
        openDataPageUrl: 'https://developer.metro.net/gtfs-schedule-data/',
        openDataPageLabel: 'Metro GTFS Schedule Data',
        licenseUrl: 'https://developer.metro.net/',
        attributionText: 'Contains data from LA Metro (LACMTA) rail service.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'bart',
      agencyName: 'BART',
      country: 'United States',
      region: 'California',
      city: 'San Francisco Bay Area',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'bart',
        agencyName: 'BART',
        province: 'California',
        vehicleTypes: [TransitVehicleType.train],
        downloadUrl:
            'https://www.bart.gov/dev/schedules/google_transit.zip',
        openDataPageUrl: 'https://www.bart.gov/schedules/developers/gtfs',
        openDataPageLabel: 'BART GTFS',
        supportsRealtime: true,
        licenseUrl:
            'https://www.bart.gov/schedules/developers/developer-license-agreement',
        attributionText:
            'Contains data from Bay Area Rapid Transit (BART) under the BART '
            'Developer License Agreement.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'caltrain',
      agencyName: 'Caltrain',
      country: 'United States',
      region: 'California',
      city: 'San Francisco Peninsula',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'caltrain',
        agencyName: 'Caltrain',
        province: 'California',
        vehicleTypes: [TransitVehicleType.train],
        downloadUrl:
            'https://data.trilliumtransit.com/gtfs/caltrain-ca-us/caltrain-ca-us.zip',
        openDataPageUrl: 'http://www.caltrain.com/developer.html',
        openDataPageLabel: 'Caltrain Developer',
        licenseUrl: 'http://www.caltrain.com/developer.html',
        attributionText: 'Contains data from Caltrain.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'vta',
      agencyName: 'VTA',
      country: 'United States',
      region: 'California',
      city: 'Santa Clara Valley',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'vta',
        agencyName: 'VTA',
        province: 'California',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.lightRail,
        ],
        downloadUrl: 'https://gtfs.vta.org/gtfs_vta.zip',
        openDataPageUrl: 'https://gtfs.vta.org/',
        openDataPageLabel: 'VTA GTFS',
        licenseUrl: 'https://gtfs.vta.org/',
        attributionText:
            'Contains data from the Santa Clara Valley Transportation Authority '
            '(VTA).',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'sound_transit',
      agencyName: 'Sound Transit',
      country: 'United States',
      region: 'Washington',
      city: 'Seattle',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'sound_transit',
        agencyName: 'Sound Transit',
        province: 'Washington',
        vehicleTypes: [
          TransitVehicleType.train,
          TransitVehicleType.lightRail,
          TransitVehicleType.bus,
        ],
        downloadUrl: 'https://gtfs.sound.obaweb.org/prod/40_gtfs.zip',
        openDataPageUrl:
            'https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/otd-downloads',
        openDataPageLabel: 'Sound Transit Open Transit Data',
        supportsRealtime: true,
        licenseUrl:
            'https://www.soundtransit.org/help-contacts/business-information/open-transit-data-otd/transit-data-terms-use',
        attributionText: 'Contains data from Sound Transit Open Transit Data.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'trimet',
      agencyName: 'TriMet',
      country: 'United States',
      region: 'Oregon',
      city: 'Portland',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'trimet',
        agencyName: 'TriMet',
        province: 'Oregon',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.train,
          TransitVehicleType.lightRail,
        ],
        downloadUrl: 'https://developer.trimet.org/schedule/gtfs.zip',
        openDataPageUrl: 'https://developer.trimet.org/GTFS.shtml',
        openDataPageLabel: 'TriMet GTFS',
        supportsRealtime: true,
        licenseUrl: 'http://developer.trimet.org/terms_of_use.shtml',
        attributionText: 'Contains data from TriMet under the TriMet Terms of Use.',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'marta',
      agencyName: 'MARTA',
      country: 'United States',
      region: 'Georgia',
      city: 'Atlanta',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'marta',
        agencyName: 'MARTA',
        province: 'Georgia',
        vehicleTypes: [
          TransitVehicleType.train,
          TransitVehicleType.bus,
        ],
        downloadUrl:
            'https://itsmarta.com/google_transit_feed/google_transit.zip',
        openDataPageUrl: 'https://itsmarta.com/app-developer-resources.aspx',
        openDataPageLabel: 'MARTA Developer Resources',
        supportsRealtime: true,
        licenseUrl: 'https://itsmarta.com/app-developer-resources.aspx',
        attributionText:
            'Contains data from the Metropolitan Atlanta Rapid Transit Authority '
            '(MARTA).',
      ),
      lines: ['All routes'],
    ),
    TransitCatalogAgency(
      agencyId: 'dart',
      agencyName: 'DART',
      country: 'United States',
      region: 'Texas',
      city: 'Dallas',
      gtfsFeed: GtfsFeedInfo(
        feedId: 'dart',
        agencyName: 'DART',
        province: 'Texas',
        vehicleTypes: [
          TransitVehicleType.bus,
          TransitVehicleType.lightRail,
          TransitVehicleType.train,
        ],
        downloadUrl:
            'https://www.dart.org/transitdata/latest/google_transit.zip',
        openDataPageUrl:
            'https://dart.org/about/about-dart/fixed-route-schedule',
        openDataPageLabel: 'DART Fixed Route Schedule',
        licenseUrl: 'https://dart.org/about/about-dart/fixed-route-schedule',
        attributionText:
            'Contains data from Dallas Area Rapid Transit (DART).',
      ),
      lines: ['All routes'],
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
