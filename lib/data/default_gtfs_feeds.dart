import '../models/gtfs_feed_info.dart';
import 'transit_catalog.dart';

/// GTFS feed definitions sourced from [TransitCatalog].
abstract final class DefaultGtfsFeeds {
  static List<GtfsFeedInfo> get feeds => TransitCatalog.gtfsFeeds;

  static GtfsFeedInfo? byId(String feedId) => TransitCatalog.feedById(feedId);

  static GtfsFeedInfo? byAgencyName(String name) =>
      TransitCatalog.feedByAgencyName(name);
}
