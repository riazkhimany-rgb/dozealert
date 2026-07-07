import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/gtfs_feed_info.dart';
import 'package:dozealert/utils/transit_data_licenses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransitDataAccessMode', () {
    test('direct download feeds use in-app download', () {
      const feed = GtfsFeedInfo(
        feedId: 'go_transit',
        agencyName: 'GO Transit',
        province: 'Ontario',
        vehicleTypes: [],
        downloadUrl: 'https://example.com/go.zip',
      );

      expect(feed.dataAccessMode, TransitDataAccessMode.inAppDownload);
    });

    test('acknowledgement feeds require manual import', () {
      const feed = GtfsFeedInfo(
        feedId: 'yrt',
        agencyName: 'YRT',
        province: 'Ontario',
        vehicleTypes: [],
        openDataPageUrl: 'https://example.com/yrt',
        requiresUserAcknowledgement: true,
      );

      expect(feed.dataAccessMode, TransitDataAccessMode.manualImport);
    });

    test('open data page without direct url requires manual import', () {
      const feed = GtfsFeedInfo(
        feedId: 'grt',
        agencyName: 'GRT',
        province: 'Ontario',
        vehicleTypes: [],
        openDataPageUrl: 'https://example.com/grt',
      );

      expect(feed.dataAccessMode, TransitDataAccessMode.manualImport);
    });
  });

  group('TransitDataLicenses', () {
    test('includes non-affiliation notice', () {
      expect(TransitDataLicenses.nonAffiliationNotice, contains('not affiliated'));
    });

    test('lists no bundled bootstrap agencies', () {
      expect(TransitDataLicenses.bundledBootstrapAgencies, isEmpty);
    });

    test('includes all catalog GTFS feeds', () {
      expect(
        TransitDataLicenses.licensedFeeds.length,
        TransitCatalog.gtfsFeeds.length,
      );
    });

    test('GO feed includes attribution and license', () {
      final goFeed = TransitCatalog.feedById('go_transit');

      expect(goFeed, isNotNull);
      expect(goFeed!.attributionText, isNotEmpty);
      expect(
        goFeed.resolvedLicenseUrl,
        'https://www.gotransit.com/en/partner-with-us/software-developers',
      );
    });

    test('TTC feed uses current Toronto open data licence page', () {
      final ttcFeed = TransitCatalog.feedById('ttc');

      expect(ttcFeed, isNotNull);
      expect(
        ttcFeed!.resolvedLicenseUrl,
        'https://open.toronto.ca/open-data-licence/',
      );
    });

    test('GRT feed uses in-app download and current licence pages', () {
      final grtFeed = TransitCatalog.feedById('grt');

      expect(grtFeed, isNotNull);
      expect(grtFeed!.dataAccessMode, TransitDataAccessMode.inAppDownload);
      expect(
        grtFeed.downloadUrl,
        'https://www.regionofwaterloo.ca/opendatadownloads/GRT_GTFS.zip',
      );
      expect(
        grtFeed.openDataPageUrl,
        'https://www.grt.ca/about-grt/open-data/',
      );
      expect(
        grtFeed.resolvedLicenseUrl,
        'https://www.regionofwaterloo.ca/government-and-council/transparency-and-accountability/open-data/',
      );
    });

    test('Brampton feed uses in-app download from ArcGIS', () {
      final bramptonFeed = TransitCatalog.feedById('brampton_transit');

      expect(bramptonFeed, isNotNull);
      expect(
        bramptonFeed!.dataAccessMode,
        TransitDataAccessMode.inAppDownload,
      );
      expect(
        bramptonFeed.downloadUrl,
        'https://www.arcgis.com/sharing/rest/content/items/a355aabd5a8c490186bdce559c9c75fb/data',
      );
      expect(
        bramptonFeed.resolvedLicenseUrl,
        'https://creativecommons.org/licenses/by/4.0/',
      );
      expect(
        bramptonFeed.attributionText,
        contains('CC BY 4.0'),
      );
    });

    test('YRT feed uses in-app download from DozeAlert mirror', () {
      final yrtFeed = TransitCatalog.feedById('yrt');

      expect(yrtFeed, isNotNull);
      expect(yrtFeed!.dataAccessMode, TransitDataAccessMode.inAppDownload);
      expect(yrtFeed.requiresUserAcknowledgement, isFalse);
      expect(
        yrtFeed.downloadUrl,
        'https://dozealert.app/gtfs-mirror/gtfs_yrt.zip',
      );
      expect(
        yrtFeed.resolvedLicenseUrl,
        'https://www.yrt.ca/en/about-us/open-data.aspx',
      );
      expect(
        yrtFeed.attributionText,
        contains('mirrored on dozealert.app'),
      );
    });
  });
}
