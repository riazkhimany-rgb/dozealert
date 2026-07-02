import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/gtfs_feed_info.dart';
import 'package:dozealert/models/transit_agency.dart';
import 'package:dozealert/models/transit_route.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'support/go_transit_test_feed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GtfsService gtfsService;

  setUp(() async {
    gtfsService = GtfsService();
    await gtfsService.initializeFromFallbackData();
  });

  test('GO Transit shows All routes before GTFS download', () {
    expect(TransitCatalog.hasCatalogLines('GO Transit'), isTrue);
    expect(
      gtfsService.linesForTransitSystem('GO Transit'),
      [TransitCatalog.allRoutesLine],
    );
  });

  test('GO Transit uses GTFS routes after feed merge', () {
    gtfsService.mergeCachedFeed(buildGoTransitTestFeed());
    expect(
      gtfsService.linesForTransitSystem('GO Transit'),
      ['Lakeshore West'],
    );
  });

  test('TTC uses All routes before GTFS download', () {
    expect(TransitCatalog.hasCatalogLines('TTC'), isFalse);
    expect(
      gtfsService.linesForTransitSystem('TTC'),
      [TransitCatalog.allRoutesLine],
    );
  });

  test('TTC subway filter returns GTFS routes after feed merge', () {
    gtfsService.mergeCachedFeed(
      GtfsCachedFeed(
        info: const GtfsFeedInfo(
          feedId: 'ttc',
          agencyName: 'TTC',
          province: 'Ontario',
          vehicleTypes: [
            TransitVehicleType.subway,
            TransitVehicleType.streetcar,
            TransitVehicleType.bus,
          ],
        ),
        agencies: const [
          TransitAgency(
            agencyId: 'ttc',
            agencyName: 'TTC',
            country: 'Canada',
            city: 'Toronto',
          ),
        ],
        routes: const [
          TransitRoute(
            routeId: 'ttc_1',
            routeName: 'Line 1 Yonge-University',
            agencyId: 'ttc',
            country: 'Canada',
            lineName: '1',
            routeShortName: '1',
            transitSystem: 'TTC',
            vehicleType: TransitVehicleType.subway,
          ),
          TransitRoute(
            routeId: 'ttc_2',
            routeName: 'Line 2 Bloor-Danforth',
            agencyId: 'ttc',
            country: 'Canada',
            lineName: '2',
            routeShortName: '2',
            transitSystem: 'TTC',
            vehicleType: TransitVehicleType.subway,
          ),
          TransitRoute(
            routeId: 'ttc_29',
            routeName: 'Dufferin',
            agencyId: 'ttc',
            country: 'Canada',
            lineName: '29',
            routeShortName: '29',
            transitSystem: 'TTC',
            vehicleType: TransitVehicleType.bus,
          ),
        ],
        stops: const [],
      ),
    );

    final subwayLines = gtfsService.lineOptionsForTransitSystem(
      'TTC',
      vehicleType: TransitVehicleType.subway,
    );
    expect(subwayLines.map((option) => option.lineName).toList(), ['1', '2']);
    expect(subwayLines.first.displayLabel, '1');
    expect(
      gtfsService
          .lineOptionsForTransitSystem(
            'TTC',
            vehicleType: TransitVehicleType.bus,
          )
          .map((option) => option.lineName),
      ['29'],
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
