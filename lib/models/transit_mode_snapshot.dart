import 'transit_agency.dart';
import 'transit_route.dart';
import 'transit_stop.dart';
import 'transit_vehicle_type.dart';

class TransitModeSnapshot {
  const TransitModeSnapshot({
    this.isActive = false,
    this.agency,
    this.route,
    this.vehicleType,
    this.destinationStop,
    this.currentStop,
    this.previousStop,
    this.nextStop,
    this.stopsRemaining = 0,
    this.usesDistanceFallback = false,
    this.status = 'Inactive',
  });

  final bool isActive;
  final TransitAgency? agency;
  final TransitRoute? route;
  final TransitVehicleType? vehicleType;
  final TransitStop? destinationStop;
  final TransitStop? currentStop;
  final TransitStop? previousStop;
  final TransitStop? nextStop;
  final int stopsRemaining;
  final bool usesDistanceFallback;
  final String status;

  static const inactive = TransitModeSnapshot();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitModeSnapshot &&
            other.isActive == isActive &&
            other.agency == agency &&
            other.route == route &&
            other.vehicleType == vehicleType &&
            other.destinationStop == destinationStop &&
            other.currentStop == currentStop &&
            other.previousStop == previousStop &&
            other.nextStop == nextStop &&
            other.stopsRemaining == stopsRemaining &&
            other.usesDistanceFallback == usesDistanceFallback &&
            other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        isActive,
        agency,
        route,
        vehicleType,
        destinationStop,
        currentStop,
        previousStop,
        nextStop,
        stopsRemaining,
        usesDistanceFallback,
        status,
      );
}
