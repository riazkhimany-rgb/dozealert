import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/models/gtfs_feed_info.dart';
import 'package:dozealert/models/gtfs_parse_schema.dart';
import 'package:dozealert/models/transit_stop.dart';
import 'package:dozealert/utils/gtfs_cache_migration.dart';

void main() {
  test('isStale is false for empty feeds', () {
    const feed = GtfsCachedFeed(
      info: GtfsFeedInfo(
        feedId: 'go_transit',
        agencyName: 'GO Transit',
        province: 'Ontario',
        vehicleTypes: [],
        parseSchemaVersion: GtfsParseSchema.legacy,
      ),
      agencies: [],
      routes: [],
      stops: [],
    );

    expect(GtfsCacheMigration.isStale(feed), isFalse);
  });

  test('isStale is false for direction-aware feeds', () {
    const feed = GtfsCachedFeed(
      info: GtfsFeedInfo(
        feedId: 'go_transit',
        agencyName: 'GO Transit',
        province: 'Ontario',
        vehicleTypes: [],
        parseSchemaVersion: GtfsParseSchema.current,
      ),
      agencies: [],
      routes: [],
      stops: [
        TransitStop(
          stopId: 'go_transit_11:d0:s1',
          stopName: 'Clarkson GO',
          latitude: 43.52,
          longitude: -79.63,
          routeId: 'go_transit_11',
          stopSequence: 1,
        ),
      ],
    );

    expect(GtfsCacheMigration.isStale(feed), isFalse);
  });

  test('isStale is true for legacy cached stop patterns', () {
    const feed = GtfsCachedFeed(
      info: GtfsFeedInfo(
        feedId: 'go_transit',
        agencyName: 'GO Transit',
        province: 'Ontario',
        vehicleTypes: [],
        parseSchemaVersion: GtfsParseSchema.legacy,
      ),
      agencies: [],
      routes: [],
      stops: [
        TransitStop(
          stopId: 'go_transit_11:1',
          stopName: 'Clarkson GO',
          latitude: 43.52,
          longitude: -79.63,
          routeId: 'go_transit_11',
          stopSequence: 1,
        ),
      ],
    );

    expect(GtfsCacheMigration.isStale(feed), isTrue);
  });
}
