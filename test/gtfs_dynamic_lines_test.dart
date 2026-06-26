import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/gtfs_feed_info.dart';
import 'package:dozealert/models/transit_agency.dart';
import 'package:dozealert/models/transit_route.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/transit_data_service.dart';

import 'support/go_transit_test_feed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GtfsService gtfsService;

  setUp(() async {
    gtfsService = GtfsService(TransitDataService());
    await gtfsService.initializeFromFallbackData();
  });

  test('GO Transit falls back to curated catalog lines before GTFS download', () {
    expect(TransitCatalog.hasCatalogLines('GO Transit'), isTrue);
    expect(
      gtfsService.linesForTransitSystem('GO Transit'),
      unorderedEquals(TransitCatalog.linesForSystem('GO Transit')),
    );
  });

  test('GO Transit uses GTFS routes after feed merge', () {
    gtfsService.mergeCachedFeed(buildGoTransitTestFeed());
    expect(
      gtfsService.linesForTransitSystem('GO Transit'),
      ['Lakeshore West'],
    );
  });

  test('bus agencies fall back to All routes before GTFS is loaded', () {
    expect(TransitCatalog.hasCatalogLines('MiWay'), isFalse);
    expect(
      gtfsService.linesForTransitSystem('MiWay'),
      [TransitCatalog.allRoutesLine],
    );
    expect(gtfsService.hasStopsForTransitSystem('MiWay'), isFalse);
  });

  test('merged GTFS feed exposes dynamic route lines', () {
    gtfsService.mergeCachedFeed(
      GtfsCachedFeed(
        info: const GtfsFeedInfo(
          feedId: 'miway',
          agencyName: 'MiWay',
          province: 'Ontario',
          vehicleTypes: [TransitVehicleType.bus],
        ),
        agencies: const [
          TransitAgency(
            agencyId: 'miway',
            agencyName: 'MiWay',
            country: 'Canada',
            city: 'Mississauga',
          ),
        ],
        routes: const [
          TransitRoute(
            routeId: 'miway_19',
            routeName: '19',
            agencyId: 'miway',
            country: 'Canada',
            lineName: '19',
            transitSystem: 'MiWay',
          ),
          TransitRoute(
            routeId: 'miway_66',
            routeName: '66',
            agencyId: 'miway',
            country: 'Canada',
            lineName: '66',
            transitSystem: 'MiWay',
          ),
        ],
        stops: const [
          TransitStop(
            stopId: 'miway_19:1',
            stopName: 'Square One',
            latitude: 43.589,
            longitude: -79.644,
            routeId: 'miway_19',
            stopSequence: 1,
          ),
          TransitStop(
            stopId: 'miway_19:2',
            stopName: 'City Centre Transit',
            latitude: 43.593,
            longitude: -79.641,
            routeId: 'miway_19',
            stopSequence: 2,
          ),
          TransitStop(
            stopId: 'miway_66:1',
            stopName: 'Square One',
            latitude: 43.589,
            longitude: -79.644,
            routeId: 'miway_66',
            stopSequence: 1,
          ),
        ],
      ),
    );

    expect(
      gtfsService.linesForTransitSystem('MiWay'),
      ['19', '66'],
    );
    expect(gtfsService.hasStopsForTransitSystem('MiWay'), isTrue);
    expect(
      gtfsService.hasStopsForTransitLine(
        transitSystem: 'MiWay',
        lineName: '19',
      ),
      isTrue,
    );
    expect(
      gtfsService.hasStopsForTransitLine(
        transitSystem: 'MiWay',
        lineName: TransitCatalog.allRoutesLine,
      ),
      isFalse,
    );

    final results = gtfsService.searchStopsForTransitSystem('MiWay', 'Square');
    expect(results.length, 1);
    expect(results.first.stop.stopName, 'Square One');
  });
}
