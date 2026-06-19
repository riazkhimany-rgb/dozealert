import 'gtfs_feed_info.dart';

/// A transit agency entry in the regional catalog.
class TransitCatalogAgency {
  const TransitCatalogAgency({
    required this.agencyId,
    required this.agencyName,
    required this.country,
    required this.region,
    required this.city,
    this.gtfsFeed,
    this.lines = const [],
  });

  final String agencyId;
  final String agencyName;
  final String country;
  final String region;
  final String city;
  final GtfsFeedInfo? gtfsFeed;
  final List<String> lines;

  bool get hasGtfsFeed => gtfsFeed != null;
}
