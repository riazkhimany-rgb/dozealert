import 'transit_stop.dart';

/// A logical station on a route — one row in the picker, may map to several platforms.
class GtfsStation {
  const GtfsStation({
    required this.stationKey,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.representativeStop,
  });

  final String stationKey;
  final String name;
  final double latitude;
  final double longitude;

  /// A platform stop used for route binding and sequence display.
  final TransitStop representativeStop;
}
