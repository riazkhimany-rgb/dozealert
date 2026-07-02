import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/utils/gtfs_stop_name_utils.dart';

void main() {
  test('normalize strips directional suffixes', () {
    expect(
      GtfsStopNameUtils.normalize('Finch Station - Northbound'),
      'Finch Station',
    );
    expect(
      GtfsStopNameUtils.normalize('Union Station Southbound'),
      'Union Station',
    );
    expect(
      GtfsStopNameUtils.normalize('Clarkson GO - WB'),
      'Clarkson GO',
    );
  });

  test('normalize strips platform suffixes', () {
    expect(
      GtfsStopNameUtils.normalize('Finch Station - Southbound Platform'),
      'Finch Station',
    );
    expect(
      GtfsStopNameUtils.normalize('Finch Station - Subway Platform'),
      'Finch Station',
    );
    expect(
      GtfsStopNameUtils.normalize('Union Station - Platform'),
      'Union Station',
    );
  });

  test('namesMatch ignores directional suffix differences', () {
    expect(
      GtfsStopNameUtils.namesMatch(
        'Finch Station',
        'Finch Station - Northbound',
      ),
      isTrue,
    );
    expect(
      GtfsStopNameUtils.namesMatch(
        'Finch Station',
        'Finch Station - Southbound Platform',
      ),
      isTrue,
    );
  });
}
