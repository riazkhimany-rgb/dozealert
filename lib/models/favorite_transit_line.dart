import '../models/transit_preferences.dart';

class FavoriteTransitLine {
  const FavoriteTransitLine({
    required this.country,
    required this.region,
    required this.transitSystem,
    required this.lineName,
  });

  final String country;
  final String region;
  final String transitSystem;
  final String lineName;

  String get label => '$transitSystem · $lineName';

  bool matches(TransitPreferences preferences) {
    return preferences.transitSystem == transitSystem &&
        preferences.defaultLine == lineName;
  }

  factory FavoriteTransitLine.fromJson(Map<String, dynamic> json) {
    return FavoriteTransitLine(
      country: json['country'] as String,
      region: json['region'] as String,
      transitSystem: json['transitSystem'] as String,
      lineName: json['lineName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'region': region,
      'transitSystem': transitSystem,
      'lineName': lineName,
    };
  }

  bool sameLine(FavoriteTransitLine other) {
    return country == other.country &&
        region == other.region &&
        transitSystem == other.transitSystem &&
        lineName == other.lineName;
  }
}
