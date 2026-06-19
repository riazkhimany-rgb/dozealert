import '../models/gtfs_feed_info.dart';
import '../models/transit_vehicle_type.dart';

abstract final class PredefinedGtfsFeeds {
  static const feeds = <GtfsFeedInfo>[
    GtfsFeedInfo(
      feedId: 'go_transit',
      agencyName: 'GO Transit',
      downloadUrl:
          'https://assets.metrolinx.com/raw/upload/Documents/TOR/GO-GTFS.zip',
      vehicleType: TransitVehicleType.train,
      supportsRealtime: true,
    ),
    GtfsFeedInfo(
      feedId: 'ttc',
      agencyName: 'TTC',
      downloadUrl:
          'https://open.toronto.ca/dataset/0a8c6a27-2d33-41ea-ba14-3f9e9e31dd42/resource/7386893a-4768-4a7f-a68c-8f0a7a0d7a90/download/gtfs.zip',
      vehicleType: TransitVehicleType.subway,
      supportsRealtime: true,
    ),
    GtfsFeedInfo(
      feedId: 'miway',
      agencyName: 'MiWay',
      downloadUrl:
          'https://www.mississauga.ca/file/COM/OpenData/MiWay_GTFS.zip',
      vehicleType: TransitVehicleType.bus,
    ),
    GtfsFeedInfo(
      feedId: 'oakville_transit',
      agencyName: 'Oakville Transit',
      downloadUrl:
          'https://www.oakville.ca/council-and-city-administration/open-data/open-data-catalogue/gtfs.zip',
      vehicleType: TransitVehicleType.bus,
    ),
    GtfsFeedInfo(
      feedId: 'burlington_transit',
      agencyName: 'Burlington Transit',
      downloadUrl:
          'https://opendata.burlington.ca/gtfs-Schedule/GTFS_Data.zip',
      vehicleType: TransitVehicleType.bus,
    ),
    GtfsFeedInfo(
      feedId: 'yrt',
      agencyName: 'YRT',
      downloadUrl: 'https://www.yrt.ca/gtfs/google_transit.zip',
      vehicleType: TransitVehicleType.bus,
      supportsRealtime: true,
    ),
    GtfsFeedInfo(
      feedId: 'brampton_transit',
      agencyName: 'Brampton Transit',
      downloadUrl:
          'https://www.brampton.ca/EN/City-Hall/Open-Data/Open-Data-Catalogue/Documents/GTFS-Brampton-Transit.zip',
      vehicleType: TransitVehicleType.bus,
      supportsRealtime: true,
    ),
    GtfsFeedInfo(
      feedId: 'hamilton_hsr',
      agencyName: 'Hamilton HSR',
      downloadUrl:
          'https://opendata.hamilton.ca/gtfs-Schedule/GTFS_Data.zip',
      vehicleType: TransitVehicleType.bus,
    ),
    GtfsFeedInfo(
      feedId: 'grt_waterloo',
      agencyName: 'GRT Waterloo',
      downloadUrl: 'https://www.grt.ca/gtfs/google_transit.zip',
      vehicleType: TransitVehicleType.bus,
    ),
    GtfsFeedInfo(
      feedId: 'oc_transpo',
      agencyName: 'OC Transpo',
      downloadUrl:
          'https://www.octranspo.com/sites/default/files/gtfs/OC_Transpo_GTFS.zip',
      vehicleType: TransitVehicleType.bus,
      supportsRealtime: true,
    ),
    GtfsFeedInfo(
      feedId: 'stm_montreal',
      agencyName: 'STM Montreal',
      downloadUrl: 'https://www.stm.info/sites/default/files/gtfs/gtfs_stm.zip',
      vehicleType: TransitVehicleType.subway,
      supportsRealtime: true,
    ),
    GtfsFeedInfo(
      feedId: 'exo_montreal',
      agencyName: 'Exo Montreal',
      downloadUrl: 'https://exo.quebec/sites/default/files/gtfs/exo_gtfs.zip',
      vehicleType: TransitVehicleType.train,
      supportsRealtime: true,
    ),
  ];

  static GtfsFeedInfo? byId(String feedId) {
    for (final feed in feeds) {
      if (feed.feedId == feedId) {
        return feed;
      }
    }
    return null;
  }
}
