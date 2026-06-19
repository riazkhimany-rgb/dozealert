import '../models/gtfs_feed_info.dart';
import '../models/transit_vehicle_type.dart';

/// Built-in GTFS feed definitions for Ontario transit agencies.
abstract final class DefaultGtfsFeeds {
  static const feeds = <GtfsFeedInfo>[
    GtfsFeedInfo(
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
    GtfsFeedInfo(
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
    GtfsFeedInfo(
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
    GtfsFeedInfo(
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
    GtfsFeedInfo(
      feedId: 'brampton_transit',
      agencyName: 'Brampton Transit',
      province: 'Ontario',
      vehicleTypes: [TransitVehicleType.bus],
      openDataPageUrl:
          'https://geohub.brampton.ca/datasets/a355aabd5a8c490186bdce559c9c75fb',
      openDataPageLabel: 'Open Brampton Transit Data',
    ),
    GtfsFeedInfo(
      feedId: 'niagara_region_transit',
      agencyName: 'Niagara Region Transit',
      province: 'Ontario',
      vehicleTypes: [TransitVehicleType.bus],
      downloadUrl: 'http://68.71.24.110/gtfs/GTFSExport.zip',
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

  static GtfsFeedInfo? byAgencyName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final feed in feeds) {
      if (feed.agencyName.toLowerCase() == normalized) {
        return feed;
      }
    }
    return null;
  }
}
