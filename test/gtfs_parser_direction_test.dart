import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/services/gtfs_parser_service.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parser keeps eastbound and westbound stop order separate', () {
    final bytes = _buildMiniGtfsZip();
    final parser = GtfsParserService();
    final result = parser.parseZipBytes(
      bytes: bytes,
      fileName: 'mini-go.zip',
      seedFeed: TransitCatalog.feedByAgencyName('GO Transit')!,
    );

    const routeId = 'go_transit_11';
    final routeStops = result.stops.where((stop) => stop.routeId == routeId);
    expect(routeStops.length, 6);

    final westbound = routeStops
        .where((stop) => stop.stopId.contains(':d0:'))
        .toList()
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    final eastbound = routeStops
        .where((stop) => stop.stopId.contains(':d1:'))
        .toList()
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

    expect(westbound.map((stop) => stop.stopName).toList(), [
      'Clarkson GO',
      'Oakville GO',
      'Bronte GO',
    ]);
    expect(eastbound.map((stop) => stop.stopName).toList(), [
      'Bronte GO',
      'Oakville GO',
      'Clarkson GO',
    ]);
  });

  test('Clarkson to Bronte westbound uses correct direction pattern', () async {
    final bytes = _buildMiniGtfsZip();
    final parser = GtfsParserService();
    final parsed = parser.parseZipBytes(
      bytes: bytes,
      fileName: 'mini-go.zip',
      seedFeed: TransitCatalog.feedByAgencyName('GO Transit')!,
    );

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

    const routeId = 'go_transit_11';
    const destination = Destination(
      name: 'Bronte GO',
      latitude: 43.4039,
      longitude: -79.7589,
    );

    final transitModeService = TransitModeService(gtfsService);
    final snapshot = transitModeService.evaluate(
      destination: destination,
      latitude: 43.5232,
      longitude: -79.6338,
      routeId: routeId,
      maxStopProximityMeters: 1000,
    );

    expect(snapshot.isActive, isTrue);
    expect(snapshot.currentStop?.stopName, 'Clarkson GO');
    expect(snapshot.destinationStop?.stopName, 'Bronte GO');
    expect(snapshot.nextStop?.stopName, 'Oakville GO');
    expect(snapshot.stopsRemaining, 2);
    expect(
      snapshot.alongRouteRemainingMeters,
      lessThan(25000),
    );
  });
}

List<int> _buildMiniGtfsZip() {
  final archive = Archive()
    ..addFile(_archiveFile('agency.txt', 'agency_id,agency_name\nGO,GO Transit\n'))
    ..addFile(
      _archiveFile(
        'routes.txt',
        'route_id,route_short_name,route_long_name,route_type,agency_id\n'
        '11,LW,Lakeshore West,2,GO\n',
      ),
    )
    ..addFile(
      _archiveFile(
        'stops.txt',
        'stop_id,stop_name,stop_lat,stop_lon\n'
        'clarkson,Clarkson GO,43.5232,-79.6338\n'
        'oakville,Oakville GO,43.4553,-79.6829\n'
        'bronte,Bronte GO,43.4039,-79.7589\n',
      ),
    )
    ..addFile(
      _archiveFile(
        'trips.txt',
        'route_id,service_id,trip_id,direction_id\n'
        '11,weekday,west,0\n'
        '11,weekday,east,1\n',
      ),
    )
    ..addFile(
      _archiveFile(
        'stop_times.txt',
        'trip_id,stop_id,stop_sequence\n'
        'west,clarkson,1\n'
        'west,oakville,2\n'
        'west,bronte,3\n'
        'east,bronte,1\n'
        'east,oakville,2\n'
        'east,clarkson,3\n',
      ),
    );

  return ZipEncoder().encode(archive)!;
}

ArchiveFile _archiveFile(String name, String content) {
  final bytes = utf8.encode(content);
  return ArchiveFile(name, bytes.length, bytes);
}
