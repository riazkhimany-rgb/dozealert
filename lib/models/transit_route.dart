import 'transit_vehicle_type.dart';

class TransitRoute {
  const TransitRoute({
    required this.routeId,
    required this.routeName,
    required this.agencyId,
    required this.country,
    required this.lineName,
    required this.transitSystem,
    this.routeShortName,
    this.vehicleType = TransitVehicleType.bus,
  });

  final String routeId;
  final String routeName;
  final String agencyId;
  final String country;
  final String lineName;
  final String transitSystem;
  final String? routeShortName;
  final TransitVehicleType vehicleType;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitRoute &&
            other.routeId == routeId &&
            other.routeName == routeName &&
            other.agencyId == agencyId &&
            other.country == country &&
            other.lineName == lineName &&
            other.transitSystem == transitSystem &&
            other.routeShortName == routeShortName &&
            other.vehicleType == vehicleType;
  }

  @override
  int get hashCode => Object.hash(
        routeId,
        routeName,
        agencyId,
        country,
        lineName,
        transitSystem,
        routeShortName,
        vehicleType,
      );
}
