import 'transit_stop.dart';
import 'transit_vehicle_type.dart';

class TransitStopSearchResult {
  const TransitStopSearchResult({
    required this.stop,
    required this.agencyName,
    required this.routeName,
    required this.vehicleType,
  });

  final TransitStop stop;
  final String agencyName;
  final String routeName;
  final TransitVehicleType vehicleType;
}
