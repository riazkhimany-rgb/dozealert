import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/utils/gtfs_station_utils.dart';

void main() {
  test('dedupeStopsToStations merges platforms at same station', () {
    const stops = [
      TransitStop(
        stopId: 'a:s1',
        stopName: 'Finch Station - Southbound Platform',
        latitude: 43.7812,
        longitude: -79.4155,
        routeId: 'line1',
        stopSequence: 12,
      ),
      TransitStop(
        stopId: 'a:s2',
        stopName: 'Finch Station - Subway Platform',
        latitude: 43.7813,
        longitude: -79.4156,
        routeId: 'line1',
        stopSequence: 13,
      ),
      TransitStop(
        stopId: 'a:s3',
        stopName: 'Sheppard Station',
        latitude: 43.761,
        longitude: -79.41,
        routeId: 'line1',
        stopSequence: 10,
      ),
    ];

    final stations = GtfsStationUtils.dedupeStopsToStations(stops);
    expect(stations.length, 2);
    expect(stations[0].name, 'Sheppard Station');
    expect(stations[1].name, 'Finch Station');
  });

  test('stationKeyForStop is stable for platform variants', () {
    const south = TransitStop(
      stopId: 'a:s1',
      stopName: 'Finch Station - Southbound Platform',
      latitude: 43.7812,
      longitude: -79.4155,
      routeId: 'line1',
      stopSequence: 1,
    );
    const subway = TransitStop(
      stopId: 'a:s2',
      stopName: 'Finch Station - Subway Platform',
      latitude: 43.7813,
      longitude: -79.4156,
      routeId: 'line1',
      stopSequence: 2,
    );

    expect(
      GtfsStationUtils.stationKeyForStop(south),
      GtfsStationUtils.stationKeyForStop(subway),
    );
  });
}
