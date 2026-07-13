import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/transit_preferences.dart';

void main() {
  test('catalog includes Canada and United States only', () {
    expect(TransitCatalog.countries, ['Canada', 'United States']);
    expect(TransitCatalog.countries, isNot(contains('United Kingdom')));
  });

  test('Ontario includes catalog agencies with GTFS feeds', () {
    final ontarioAgencies = TransitCatalog.agenciesForRegion('Canada', 'Ontario');
    final ontarioFeeds = TransitCatalog.gtfsFeedsForRegion('Canada', 'Ontario');

    const ontarioAgenciesFromList = [
      'GO Transit',
      'TTC',
      'MiWay',
      'Brampton Transit',
      'York Region Transit',
      'Durham Region Transit',
      'Milton Transit',
      'Oakville Transit',
      'Burlington Transit',
      'Hamilton Street Railway',
      'Grand River Transit',
      'Guelph Transit',
      'London Transit',
      'OC Transpo',
      'Barrie Transit',
      'Niagara Region Transit',
      'Kingston Transit',
      'Windsor Transit',
      'Sault Ste. Marie Transit',
      'Thunder Bay Transit',
    ];

    for (final agency in ontarioAgenciesFromList) {
      expect(ontarioAgencies, contains(agency));
    }

    expect(ontarioFeeds.length, 20);

    for (final feed in ontarioFeeds) {
      expect(ontarioAgencies, contains(feed.agencyName));
    }

    expect(TransitCatalog.feedById('guelph_transit')?.hasDirectDownload, isTrue);
    expect(TransitCatalog.feedById('oc_transpo')?.hasDirectDownload, isTrue);
  });

  test('new Canadian regions include direct-download GTFS feeds', () {
    expect(
      TransitCatalog.agenciesForRegion('Canada', 'Alberta'),
      containsAll(['Calgary Transit', 'Edmonton Transit Service']),
    );
    expect(
      TransitCatalog.agenciesForRegion('Canada', 'Manitoba'),
      contains('Winnipeg Transit'),
    );
    expect(
      TransitCatalog.agenciesForRegion('Canada', 'Nova Scotia'),
      contains('Halifax Transit'),
    );
    expect(
      TransitCatalog.agenciesForRegion('Canada', 'British Columbia'),
      containsAll([
        'TransLink Vancouver',
        'BC Transit Victoria',
        'BC Transit Kelowna',
        'BC Transit Nanaimo',
        'BC Transit Kamloops',
      ]),
    );

    for (final feedId in [
      'calgary_transit',
      'edmonton_transit',
      'winnipeg_transit',
      'halifax_transit',
      'stm_montreal',
      'exo_montreal',
      'translink_vancouver',
      'bc_transit_victoria',
      'bc_transit_kelowna',
      'bc_transit_nanaimo',
      'bc_transit_kamloops',
    ]) {
      expect(
        TransitCatalog.feedById(feedId)?.hasDirectDownload,
        isTrue,
        reason: feedId,
      );
    }
  });

  test('normalize migrates legacy preferences without region', () {
    final normalized = TransitCatalog.normalize(
      const TransitPreferences(
        country: 'Canada',
        transitSystem: 'TTC',
        defaultLine: 'Line 1',
      ),
    );

    expect(normalized.region, 'Ontario');
    expect(normalized.transitSystem, 'TTC');
    expect(normalized.defaultLine, 'Line 1');
  });

  test('normalize resets invalid United Kingdom country', () {
    final normalized = TransitCatalog.normalize(
      const TransitPreferences(
        country: 'United Kingdom',
        region: 'England',
        transitSystem: 'National Rail',
        defaultLine: 'West Coast Main Line',
      ),
    );

    expect(normalized.country, 'Canada');
    expect(normalized.region, 'Ontario');
    expect(normalized.transitSystem, 'GO Transit');
  });
}
