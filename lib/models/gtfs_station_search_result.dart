import 'gtfs_station.dart';
import 'transit_vehicle_type.dart';

class GtfsStationSearchResult {
  const GtfsStationSearchResult({
    required this.station,
    required this.agencyName,
    required this.routeName,
    required this.vehicleType,
  });

  final GtfsStation station;
  final String agencyName;
  final String routeName;
  final TransitVehicleType vehicleType;
}
