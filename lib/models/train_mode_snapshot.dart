import 'transit_agency.dart';
import 'transit_route.dart';
import 'transit_stop.dart';

class TrainModeSnapshot {
  const TrainModeSnapshot({
    this.isActive = false,
    this.agency,
    this.route,
    this.destinationStation,
    this.currentNearestStation,
    this.previousStation,
    this.nextStation,
    this.stationsRemaining = 0,
    this.status = 'Inactive',
  });

  final bool isActive;
  final TransitAgency? agency;
  final TransitRoute? route;
  final TransitStop? destinationStation;
  final TransitStop? currentNearestStation;
  final TransitStop? previousStation;
  final TransitStop? nextStation;
  final int stationsRemaining;
  final String status;

  static const inactive = TrainModeSnapshot();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TrainModeSnapshot &&
            other.isActive == isActive &&
            other.agency == agency &&
            other.route == route &&
            other.destinationStation == destinationStation &&
            other.currentNearestStation == currentNearestStation &&
            other.previousStation == previousStation &&
            other.nextStation == nextStation &&
            other.stationsRemaining == stationsRemaining &&
            other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        isActive,
        agency,
        route,
        destinationStation,
        currentNearestStation,
        previousStation,
        nextStation,
        stationsRemaining,
        status,
      );
}
