import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/services/gtfs_parser_service.dart';

void main() {
  test('groups trips by headsign when direction_id is uniform', () {
    final bytes = _buildHeadsignOnlyZip();
    final parser = GtfsParserService();
    final result = parser.parseZipBytes(
      bytes: bytes,
      fileName: 'headsign.zip',
      seedFeed: TransitCatalog.feedByAgencyName('TTC')!,
    );

    const routeId = 'ttc_1';
    final north = result.stops
        .where((stop) => stop.stopId.contains(':hnorth:'))
        .toList()
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    final south = result.stops
        .where((stop) => stop.stopId.contains(':hsouth:'))
        .toList()
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));

    expect(north.map((stop) => stop.stopName).toList(), ['Alpha', 'Beta']);
    expect(south.map((stop) => stop.stopName).toList(), ['Beta', 'Alpha']);
    expect(north.every((stop) => stop.routeId == routeId), isTrue);
  });

  test('resolves parent_station to parent stop coordinates', () {
    final bytes = _buildParentStationZip();
    final parser = GtfsParserService();
    final result = parser.parseZipBytes(
      bytes: bytes,
      fileName: 'parent.zip',
      seedFeed: TransitCatalog.feedByAgencyName('TTC')!,
    );

    expect(result.stops.length, 2);
    expect(result.stops.every((stop) => stop.stopName == 'Union Station'), isTrue);
    expect(
      result.stops.map((stop) => stop.latitude.toStringAsFixed(4)).toSet(),
      {'43.6453'},
    );
  });

  test('classifies TTC subway streetcar and bus routes', () {
    final bytes = _buildMixedModeZip();
    final parser = GtfsParserService();
    final result = parser.parseZipBytes(
      bytes: bytes,
      fileName: 'ttc.zip',
      seedFeed: TransitCatalog.feedByAgencyName('TTC')!,
    );

    final routesByShortName = {
      for (final route in result.routes)
        route.routeShortName!: route.vehicleType,
    };

    expect(routesByShortName['1'], TransitVehicleType.subway);
    expect(routesByShortName['2'], TransitVehicleType.subway);
    expect(routesByShortName['510'], TransitVehicleType.streetcar);
    expect(routesByShortName['29'], TransitVehicleType.bus);
  });
}

List<int> _buildHeadsignOnlyZip() {
  final archive = Archive()
    ..addFile(_file('agency.txt', 'agency_id,agency_name\n1,TTC\n'))
    ..addFile(
      _file(
        'routes.txt',
        'route_id,route_short_name,route_long_name,route_type,agency_id\n'
        '1,1,Line 1,1,1\n',
      ),
    )
    ..addFile(
      _file(
        'stops.txt',
        'stop_id,stop_name,stop_lat,stop_lon\n'
        'a,Alpha,43.70,-79.40\n'
        'b,Beta,43.65,-79.38\n',
      ),
    )
    ..addFile(
      _file(
        'trips.txt',
        'route_id,service_id,trip_id,direction_id,trip_headsign\n'
        '1,weekday,north,0,North\n'
        '1,weekday,south,0,South\n',
      ),
    )
    ..addFile(
      _file(
        'stop_times.txt',
        'trip_id,stop_id,stop_sequence\n'
        'north,a,1\n'
        'north,b,2\n'
        'south,b,1\n'
        'south,a,2\n',
      ),
    );

  return ZipEncoder().encode(archive)!;
}

List<int> _buildParentStationZip() {
  final archive = Archive()
    ..addFile(_file('agency.txt', 'agency_id,agency_name\n1,TTC\n'))
    ..addFile(
      _file(
        'routes.txt',
        'route_id,route_short_name,route_long_name,route_type,agency_id\n'
        '1,1,Line 1,1,1\n',
      ),
    )
    ..addFile(
      _file(
        'stops.txt',
        'stop_id,stop_name,stop_lat,stop_lon,parent_station\n'
        'parent,Union Station,43.6453,-79.3806,\n'
        'plat_n,Union - Northbound,43.6454,-79.3807,parent\n'
        'plat_s,Union - Southbound,43.6452,-79.3805,parent\n',
      ),
    )
    ..addFile(
      _file(
        'trips.txt',
        'route_id,service_id,trip_id,direction_id,trip_headsign\n'
        '1,weekday,t1,0,North\n'
        '1,weekday,t2,1,South\n',
      ),
    )
    ..addFile(
      _file(
        'stop_times.txt',
        'trip_id,stop_id,stop_sequence\n'
        't1,plat_n,1\n'
        't2,plat_s,1\n',
      ),
    );

  return ZipEncoder().encode(archive)!;
}

List<int> _buildMixedModeZip() {
  final archive = Archive()
    ..addFile(_file('agency.txt', 'agency_id,agency_name\n1,TTC\n'))
    ..addFile(
      _file(
        'routes.txt',
        'route_id,route_short_name,route_long_name,route_type,agency_id\n'
        '1,1,Line 1 Yonge-University,1,1\n'
        '2,2,Line 2 Bloor-Danforth,1,1\n'
        '510,510,Spadina,0,1\n'
        '29,29,Dufferin,3,1\n',
      ),
    )
    ..addFile(
      _file(
        'stops.txt',
        'stop_id,stop_name,stop_lat,stop_lon\n'
        'a,Alpha,43.70,-79.40\n',
      ),
    )
    ..addFile(
      _file(
        'trips.txt',
        'route_id,service_id,trip_id,direction_id,trip_headsign\n'
        '1,weekday,t1,0,North\n',
      ),
    )
    ..addFile(
      _file(
        'stop_times.txt',
        'trip_id,stop_id,stop_sequence\n'
        't1,a,1\n',
      ),
    );

  return ZipEncoder().encode(archive)!;
}

ArchiveFile _file(String name, String content) {
  final bytes = utf8.encode(content);
  return ArchiveFile(name, bytes.length, bytes);
}
