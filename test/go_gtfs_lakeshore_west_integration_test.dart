import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/services/gtfs_parser_service.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real GO GTFS Lakeshore West Clarkson to Bronte westbound', () async {
    final fixture = File('test/fixtures/GO-GTFS.zip');
    if (!fixture.existsSync()) {
      return;
    }

    final parser = GtfsParserService();
    final parsed = parser.parseZipBytes(
      bytes: fixture.readAsBytesSync(),
      fileName: 'GO-GTFS.zip',
      seedFeed: TransitCatalog.feedByAgencyName('GO Transit')!,
    );

    const routeId = 'go_transit_06260926-LW';
    final routeStops = parsed.stops.where((stop) => stop.routeId == routeId);
    expect(routeStops.length, greaterThan(20));

    final gtfsService = GtfsService();
    await gtfsService.initializeFromFallbackData();
    gtfsService.mergeCachedFeed(
      GtfsCachedFeed(
        info: parsed.feedInfo,
        agencies: parsed.agencies,
        routes: parsed.routes,
        stops: parsed.stops,
      ),
    );

    const destination = Destination(
      name: 'Bronte GO',
      latitude: 43.416774,
      longitude: -79.722294,
    );

    final snapshot = TransitModeService(gtfsService).evaluate(
      destination: destination,
      latitude: 43.513127,
      longitude: -79.633206,
      routeId: routeId,
      maxStopProximityMeters: 1000,
    );

    expect(snapshot.isActive, isTrue);
    expect(snapshot.currentStop?.stopName, contains('Clarkson'));
    expect(snapshot.nextStop?.stopName, contains('Oakville'));
    expect(snapshot.stopsRemaining, 2);
    expect(snapshot.alongRouteRemainingMeters, lessThan(25000));
  });
}
