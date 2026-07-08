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
