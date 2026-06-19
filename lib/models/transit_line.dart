import 'transit_station.dart';

class TransitLine {
  const TransitLine({
    required this.country,
    required this.transitSystem,
    required this.lineName,
    required this.stations,
  });

  final String country;
  final String transitSystem;
  final String lineName;
  final List<TransitStation> stations;

  factory TransitLine.fromJson(Map<String, dynamic> json) {
    final stationList = json['stations'] as List<dynamic>? ?? const [];
    return TransitLine(
      country: json['country'] as String,
      transitSystem: json['transitSystem'] as String,
      lineName: json['lineName'] as String,
      stations: stationList
          .map((entry) => TransitStation.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'transitSystem': transitSystem,
      'lineName': lineName,
      'stations': stations.map((station) => station.toJson()).toList(),
    };
  }
}
