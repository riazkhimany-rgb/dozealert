import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/models/gtfs_feed_info.dart';
import 'package:dozealert/models/transit_agency.dart';
import 'package:dozealert/models/transit_route.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
/// Minimal GO Transit feed for unit tests after bundled JSON bootstrap removal.
GtfsCachedFeed buildGoTransitTestFeed() {
  const routeId = 'go_transit_lakeshore_west';
  const stops = [
    TransitStop(
      stopId: '$routeId:1',
      stopName: 'Union GO',
      latitude: 43.6453,
      longitude: -79.3806,
      routeId: routeId,
      stopSequence: 1,
    ),
    TransitStop(
      stopId: '$routeId:2',
      stopName: 'Exhibition GO',
      latitude: 43.6359,
      longitude: -79.4187,
      routeId: routeId,
      stopSequence: 2,
    ),
    TransitStop(
      stopId: '$routeId:3',
      stopName: 'Bronte GO',
      latitude: 43.4039,
      longitude: -79.7589,
      routeId: routeId,
      stopSequence: 3,
    ),
  ];

  return GtfsCachedFeed(
    info: GtfsFeedInfo(
      feedId: 'go_transit',
      agencyName: 'GO Transit',
      province: 'Ontario',
      vehicleTypes: const [TransitVehicleType.train, TransitVehicleType.bus],
      status: GtfsFeedStatus.downloaded,
      routeCount: 1,
      stopCount: stops.length,
    ),
    agencies: const [
      TransitAgency(
        agencyId: 'go_transit',
        agencyName: 'GO Transit',
        country: 'Canada',
        city: 'Toronto',
      ),
    ],
    routes: const [
      TransitRoute(
        routeId: routeId,
        routeName: 'Lakeshore West',
        agencyId: 'go_transit',
        country: 'Canada',
        lineName: 'Lakeshore West',
        transitSystem: 'GO Transit',
        vehicleType: TransitVehicleType.train,
      ),
    ],
    stops: stops,
  );
}
