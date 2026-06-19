import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';
import 'package:dozealert/services/transit_data_service.dart';
import 'package:dozealert/models/destination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GtfsService gtfsService;
  late TransitModeService transitModeService;

  setUp(() async {
    gtfsService = GtfsService(TransitDataService());
    await gtfsService.initializeFromFallbackData();
    transitModeService = TransitModeService(gtfsService);
  });

  test('detects GO Transit route for Bronte GO', () {
    final detection = gtfsService.detectAgencyFromDestination('Bronte GO');

    expect(detection, isNotNull);
    expect(detection!.agency.agencyName, 'GO Transit');
    expect(detection.route?.lineName, 'Lakeshore West');
  });

  test('detects Exo for Montreal Central', () {
    final detection = gtfsService.detectAgencyFromDestination('Montreal Central');

    expect(detection, isNotNull);
    expect(detection!.agency.agencyId, 'exo_montreal');
  });

  test('global search finds Bronte GO', () {
    final results = gtfsService.searchStops('Bro');

    expect(results.any((stop) => stop.stopName == 'Bronte GO'), isTrue);
  });

  test('global search result includes agency metadata', () {
    final results = gtfsService.searchStopResults('Finch');

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
    );

    expect(snapshot.isActive, isTrue);
    expect(snapshot.currentStop?.stopName, 'Oakville GO');
    expect(snapshot.destinationStop?.stopName, 'Bronte GO');
    expect(snapshot.stopsRemaining, 1);
    expect(snapshot.nextStop?.stopName, 'Bronte GO');
  });
}
