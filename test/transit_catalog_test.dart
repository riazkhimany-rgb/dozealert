import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/transit_preferences.dart';

void main() {
  test('catalog includes Canada and United States only', () {
    expect(TransitCatalog.countries, ['Canada', 'United States']);
    expect(TransitCatalog.countries, isNot(contains('United Kingdom')));
  });

  test('Ontario includes GTA transit agencies with GTFS feeds', () {
    final ontarioAgencies = TransitCatalog.agenciesForRegion('Canada', 'Ontario');
    final ontarioFeeds = TransitCatalog.gtfsFeedsForRegion('Canada', 'Ontario');

    const gtaAgencies = [
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
    ];

    for (final agency in gtaAgencies) {
      expect(ontarioAgencies, contains(agency));
    }

    expect(ontarioAgencies, contains('Grand River Transit'));
    expect(ontarioAgencies, contains('Niagara Region Transit'));
    expect(ontarioAgencies, contains('OC Transpo'));
    expect(ontarioFeeds.length, 12);

    for (final feed in ontarioFeeds) {
      expect(ontarioAgencies, contains(feed.agencyName));
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
