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

  factory TransitCatalogAgency.fromJson(Map<String, dynamic> json) {
    final gtfsJson = json['gtfsFeed'];
    return TransitCatalogAgency(
      agencyId: json['agencyId'] as String,
      agencyName: json['agencyName'] as String,
      country: json['country'] as String,
      region: json['region'] as String,
      city: json['city'] as String,
      gtfsFeed: gtfsJson is Map<String, dynamic>
          ? GtfsFeedInfo.fromCatalogJson(gtfsJson)
          : null,
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toCatalogJson() {
    return {
      'agencyId': agencyId,
      'agencyName': agencyName,
      'country': country,
      'region': region,
      'city': city,
      if (gtfsFeed != null) 'gtfsFeed': gtfsFeed!.toCatalogJson(),
      'lines': lines,
    };
  }

  Map<String, dynamic> toJson() => toCatalogJson();
}
