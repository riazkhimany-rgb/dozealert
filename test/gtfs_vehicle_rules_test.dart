import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/models/transit_vehicle_type.dart';
import 'package:dozealert/utils/gtfs_vehicle_rules.dart';

void main() {
  test('classifies TTC subway streetcar and bus routes from catalog rules', () {
    expect(
      GtfsVehicleRules.inferFromRouteNames(
        feedId: 'ttc',
        routeShortName: '1',
        routeLongName: 'Yonge-University',
        defaultType: TransitVehicleType.bus,
      ),
      TransitVehicleType.subway,
    );
    expect(
      GtfsVehicleRules.inferFromRouteNames(
        feedId: 'ttc',
        routeShortName: '505',
        routeLongName: 'Dundas',
        defaultType: TransitVehicleType.bus,
      ),
      TransitVehicleType.streetcar,
    );
    expect(
      GtfsVehicleRules.inferFromRouteNames(
        feedId: 'ttc',
        routeShortName: '36',
        routeLongName: 'Finch West',
        defaultType: TransitVehicleType.subway,
      ),
      TransitVehicleType.bus,
    );
  });
}
