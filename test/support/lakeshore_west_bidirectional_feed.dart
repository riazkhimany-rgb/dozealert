import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/models/gtfs_feed_info.dart';
import 'package:dozealert/models/transit_agency.dart';
import 'package:dozealert/models/transit_route.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';

/// Lakeshore West with separate eastbound/westbound GTFS direction patterns.
GtfsCachedFeed buildLakeshoreWestBidirectionalFeed() {
  const routeId = 'go_transit_11';
  const westbound = [
    ('Union GO', 43.6453, -79.3806),
    ('Exhibition GO', 43.6359, -79.4187),
    ('Mimico GO', 43.6172, -79.4946),
    ('Long Branch GO', 43.591, -79.54),
    ('Port Credit GO', 43.5534, -79.5855),
    ('Clarkson GO', 43.5232, -79.6338),
    ('Oakville GO', 43.4553, -79.6829),
    ('Bronte GO', 43.4039, -79.7589),
    ('Appleby GO', 43.3811, -79.7624),
    ('Burlington GO', 43.3416, -79.8094),
    ('Aldershot GO', 43.3138, -79.855),
    ('West Harbour GO', 43.265, -79.8672),
    ('Confederation GO', 43.2183, -79.8628),
    ('Centennial GO', 43.2189, -79.738),
    ('St. Catharines GO', 43.1478, -79.2557),
    ('Niagara Falls GO', 43.1099, -79.0613),
  ];

  final stops = <TransitStop>[];
  for (var direction = 0; direction <= 1; direction++) {
    final stations = direction == 0 ? westbound : westbound.reversed.toList();
    for (var index = 0; index < stations.length; index++) {
      final station = stations[index];
      final sequence = index + 1;
      stops.add(
        TransitStop(
          stopId: '$routeId:d$direction:s$sequence',
          stopName: station.$1,
          latitude: station.$2,
          longitude: station.$3,
          routeId: routeId,
          stopSequence: sequence,
        ),
      );
    }
  }

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
        routeShortName: '11',
        transitSystem: 'GO Transit',
        vehicleType: TransitVehicleType.train,
      ),
    ],
    stops: stops,
  );
}
