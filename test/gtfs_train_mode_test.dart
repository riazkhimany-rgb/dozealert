import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/train_mode_service.dart';
import 'package:dozealert/services/transit_data_service.dart';
import 'package:dozealert/models/destination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GtfsService gtfsService;
  late TrainModeService trainModeService;

  setUp(() async {
    gtfsService = GtfsService(TransitDataService());
    await gtfsService.initializeFromFallbackData();
    trainModeService = TrainModeService(gtfsService);
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

  test('train mode calculates stations remaining', () {
    const destination = Destination(
      name: 'Bronte GO',
      latitude: 43.4039,
      longitude: -79.7589,
    );

    final snapshot = trainModeService.evaluate(
      destination: destination,
      latitude: 43.4553,
      longitude: -79.6829,
      routeId: 'go_transit_lakeshore_west',
    );

    expect(snapshot.isActive, isTrue);
    expect(snapshot.currentNearestStation?.stopName, 'Oakville GO');
    expect(snapshot.destinationStation?.stopName, 'Bronte GO');
    expect(snapshot.stationsRemaining, 1);
    expect(snapshot.nextStation?.stopName, 'Bronte GO');
  });
}
