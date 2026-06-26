import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';
import 'package:dozealert/services/transit_data_service.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/models/transit_route.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';

import 'support/go_transit_test_feed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GtfsService gtfsService;
  late TransitModeService transitModeService;

  setUp(() async {
    gtfsService = GtfsService(TransitDataService());
    await gtfsService.initializeFromFallbackData();
    gtfsService.mergeCachedFeed(buildGoTransitTestFeed());
    transitModeService = TransitModeService(gtfsService);
  });

  test('detects GO Transit route for Bronte GO', () {
    final detection = gtfsService.detectAgencyFromDestination('Bronte GO');

    expect(detection, isNotNull);
    expect(detection!.agency.agencyName, 'GO Transit');
    expect(detection.route?.lineName, 'Lakeshore West');
  });

  test('detects agency from coordinates when stop name does not match', () {
    final detection = gtfsService.detectAgencyFromDestinationAt(
      destinationName: 'My saved stop',
      latitude: 43.4039,
      longitude: -79.7589,
    );

    expect(detection, isNotNull);
    expect(detection!.agency.agencyName, 'GO Transit');
    expect(detection.route?.lineName, 'Lakeshore West');
    expect(detection.stop?.stopName, 'Bronte GO');
  });

  test('routeForTransitLine matches GTFS route number and long name', () {
    const westRouteId = 'go_transit_lakeshore_west';
    gtfsService.mergeCachedFeed(
      GtfsCachedFeed(
        info: buildGoTransitTestFeed().info,
        agencies: buildGoTransitTestFeed().agencies,
        routes: const [
          TransitRoute(
            routeId: westRouteId,
            routeName: 'Lakeshore West',
            agencyId: 'go_transit',
            country: 'Canada',
            lineName: '11',
            routeShortName: '11',
            transitSystem: 'GO Transit',
            vehicleType: TransitVehicleType.train,
          ),
        ],
        stops: buildGoTransitTestFeed().stops,
      ),
    );

    expect(
      gtfsService.routeForTransitLine(
        transitSystem: 'GO Transit',
        lineName: 'Lakeshore West',
      )?.routeId,
      westRouteId,
    );
    expect(
      gtfsService.routeForTransitLine(
        transitSystem: 'GO Transit',
        lineName: '11',
      )?.routeId,
      westRouteId,
    );
    expect(
      gtfsService.transitLineInfoForRoute(
        gtfsService.routeForTransitLine(
          transitSystem: 'GO Transit',
          lineName: '11',
        )!,
      ).badge,
      'GO Transit · Lakeshore West',
    );
    expect(
      gtfsService.selectedLineDisplayLabel(
        transitSystem: 'GO Transit',
        lineRef: '11',
      ),
      'GO Transit - 11 - Lakeshore West',
    );
  });

  test('detectDestinationOnRoute prefers selected line at shared stop', () {
    const westRouteId = 'go_transit_lakeshore_west';
    const eastRouteId = 'go_transit_lakeshore_east';
    final baseFeed = buildGoTransitTestFeed();
    gtfsService.mergeCachedFeed(
      GtfsCachedFeed(
        info: baseFeed.info,
        agencies: baseFeed.agencies,
        routes: [
          ...baseFeed.routes,
          const TransitRoute(
            routeId: eastRouteId,
            routeName: 'Lakeshore East',
            agencyId: 'go_transit',
            country: 'Canada',
            lineName: 'Lakeshore East',
            transitSystem: 'GO Transit',
            vehicleType: TransitVehicleType.train,
          ),
        ],
        stops: [
          ...baseFeed.stops,
          const TransitStop(
            stopId: '$eastRouteId:3',
            stopName: 'Bronte GO',
            latitude: 43.4039,
            longitude: -79.7589,
            routeId: eastRouteId,
            stopSequence: 3,
          ),
        ],
      ),
    );

    final westDetection = gtfsService.detectDestinationOnRoute(
      destinationName: 'Bronte GO',
      routeId: westRouteId,
      latitude: 43.4039,
      longitude: -79.7589,
    );
    final eastDetection = gtfsService.detectDestinationOnRoute(
      destinationName: 'Bronte GO',
      routeId: eastRouteId,
      latitude: 43.4039,
      longitude: -79.7589,
    );

    expect(westDetection?.route?.lineName, 'Lakeshore West');
    expect(eastDetection?.route?.lineName, 'Lakeshore East');
  });

  test('does not detect stops without downloaded GTFS data', () {
    final detection =
        gtfsService.detectAgencyFromDestination('Montreal Central');

    expect(detection, isNull);
  });

  test('global search finds Bronte GO', () {
    final results = gtfsService.searchStops('Bro');

    expect(results.any((stop) => stop.stopName == 'Bronte GO'), isTrue);
  });

  test('global search result includes agency metadata', () {
    final results = gtfsService.searchStopResults('Union');

    expect(results, isNotEmpty);
    expect(results.first.agencyName, isNotEmpty);
    expect(results.first.routeName, isNotEmpty);
  });

  test('lists stops for selected GO Transit line', () {
    final stops = gtfsService.stopsForTransitLine(
      transitSystem: 'GO Transit',
      lineName: 'Lakeshore West',
    );

    expect(stops, isNotEmpty);
    expect(stops.any((stop) => stop.stopName == 'Bronte GO'), isTrue);
    expect(stops.first.stopSequence, lessThan(stops.last.stopSequence));
  });

  test('filters stops on a line by query', () {
    final route = gtfsService.routeForTransitLine(
      transitSystem: 'GO Transit',
      lineName: 'Lakeshore West',
    );
    expect(route, isNotNull);

    final filtered = gtfsService.filterStopsOnRoute(
      routeId: route!.routeId,
      query: 'Bro',
    );

    expect(filtered.any((stop) => stop.stopName == 'Bronte GO'), isTrue);
  });

  test('getStopsFromCurrentToDestination lists segment along route', () {
    const destination = Destination(
      name: 'Bronte GO',
      latitude: 43.4039,
      longitude: -79.7589,
    );

    final snapshot = transitModeService.evaluate(
      destination: destination,
      latitude: 43.4553,
      longitude: -79.6829,
      routeId: 'go_transit_lakeshore_west',
      maxStopProximityMeters: 1000,
    );

    expect(snapshot.isActive, isTrue);

    final segment = transitModeService.getStopsFromCurrentToDestination(
      currentStop: snapshot.currentStop!,
      destinationStop: snapshot.destinationStop!,
      routeId: snapshot.route!.routeId,
    );

    expect(segment.length, 2);
    expect(segment.first.stopName, 'Exhibition GO');
    expect(segment.last.stopName, 'Bronte GO');
  });

  test('transit mode calculates stops remaining', () {
    const destination = Destination(
      name: 'Bronte GO',
      latitude: 43.4039,
      longitude: -79.7589,
    );

    final snapshot = transitModeService.evaluate(
      destination: destination,
      latitude: 43.4553,
      longitude: -79.6829,
      routeId: 'go_transit_lakeshore_west',
      maxStopProximityMeters: 1000,
    );

    expect(snapshot.isActive, isTrue);
    expect(snapshot.currentStop?.stopName, 'Exhibition GO');
    expect(snapshot.destinationStop?.stopName, 'Bronte GO');
    expect(snapshot.stopsRemaining, 1);
    expect(snapshot.nextStop?.stopName, 'Bronte GO');
  });

  test('transit mode stays inactive when far from the route at home', () {
    const destination = Destination(
      name: 'Bronte GO',
      latitude: 43.4039,
      longitude: -79.7589,
    );

    // Residential Mississauga — roughly 13+ km from Bronte, not at a GO platform.
    final snapshot = transitModeService.evaluate(
      destination: destination,
      latitude: 43.589,
      longitude: -79.644,
      routeId: 'go_transit_lakeshore_west',
      maxStopProximityMeters: 1000,
    );

    expect(snapshot.isActive, isFalse);
  });
}
