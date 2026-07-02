import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/models/gtfs_feed_info.dart';
import 'package:dozealert/models/transit_agency.dart';
import 'package:dozealert/models/transit_route.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransitModeService stop matching', () {
    const routeId = 'bus_route_1';
    const destination = TransitStop(
      stopId: '$routeId:4',
      stopName: 'Destination',
      latitude: 43.6700,
      longitude: -79.3800,
      routeId: routeId,
      stopSequence: 4,
    );
    const stops = [
      TransitStop(
        stopId: '$routeId:1',
        stopName: 'NearA',
        latitude: 43.6500,
        longitude: -79.3800,
        routeId: routeId,
        stopSequence: 1,
      ),
      TransitStop(
        stopId: '$routeId:2',
        stopName: 'NearB',
        latitude: 43.6502,
        longitude: -79.3802,
        routeId: routeId,
        stopSequence: 2,
      ),
      TransitStop(
        stopId: '$routeId:3',
        stopName: 'NearC',
        latitude: 43.6504,
        longitude: -79.3804,
        routeId: routeId,
        stopSequence: 3,
      ),
      destination,
    ];

    late TransitModeService transitModeService;

    setUp(() async {
      final gtfsService = GtfsService();
      await gtfsService.initializeFromFallbackData();
      gtfsService.mergeCachedFeed(
        GtfsCachedFeed(
          info: GtfsFeedInfo(
            feedId: 'bus_test',
            agencyName: 'Test Bus',
            province: 'Ontario',
            vehicleTypes: const [TransitVehicleType.bus],
            status: GtfsFeedStatus.downloaded,
            routeCount: 1,
            stopCount: stops.length,
          ),
          agencies: const [
            TransitAgency(
              agencyId: 'bus_test',
              agencyName: 'Test Bus',
              country: 'Canada',
              city: 'Toronto',
            ),
          ],
          routes: const [
            TransitRoute(
              routeId: routeId,
              routeName: 'Test Line',
              agencyId: 'bus_test',
              country: 'Canada',
              lineName: 'Test Line',
              transitSystem: 'Test Bus',
              vehicleType: TransitVehicleType.bus,
            ),
          ],
          stops: stops,
        ),
      );
      transitModeService = TransitModeService(gtfsService);
    });

    test('nearest-stop fallback prefers earliest stop when several are nearby', () {
      final current = transitModeService.getCurrentStop(
        latitude: 43.6501,
        longitude: -79.3801,
        routeId: routeId,
        maxProximityMeters: 400,
        destinationStop: destination,
      );

      expect(current?.stopName, 'NearA');
    });
  });
}
