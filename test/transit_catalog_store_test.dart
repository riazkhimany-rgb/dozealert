import 'dart:convert';

import 'package:dozealert/data/transit_catalog_bundled.dart';
import 'package:dozealert/data/transit_catalog_registry.dart';
import 'package:dozealert/models/transit_catalog_manifest.dart';
import 'package:dozealert/services/transit_catalog_store.dart';
import 'package:dozealert/utils/app_version_compare.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return {
        'appName': 'DozeAlert',
        'packageName': 'app.dozealert',
        'version': '1.1.0',
        'buildNumber': '37',
      };
    });
  });

  group('AppVersionCompare', () {
    test('compares semantic versions', () {
      expect(AppVersionCompare.compare('1.1.0', '1.0.9'), greaterThan(0));
      expect(AppVersionCompare.compare('1.0.0', '1.0.0'), 0);
      expect(AppVersionCompare.isAtLeast('1.1.0', '1.1.0'), isTrue);
      expect(AppVersionCompare.isAtLeast('1.0.9', '1.1.0'), isFalse);
    });
  });

  group('TransitCatalogManifest', () {
    test('round-trips through JSON', () {
      final manifest = TransitCatalogBundled.manifest;
      final decoded = TransitCatalogManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.catalogVersion, manifest.catalogVersion);
      expect(decoded.agencies.length, manifest.agencies.length);
      expect(decoded.agencies.first.agencyId, manifest.agencies.first.agencyId);
    });

    test('rejects future schema versions for this app', () {
      final manifest = TransitCatalogManifest(
        catalogVersion: 99,
        schemaVersion: TransitCatalogManifest.supportedSchemaVersion + 1,
        minAppVersion: '1.0.0',
        countries: const ['Canada'],
        defaultRegionByCountry: const {'Canada': 'Ontario'},
        agencies: const [],
      );

      expect(manifest.isCompatibleWithApp('9.9.9'), isFalse);
    });
  });

  group('TransitCatalogStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TransitCatalogBundled.manifest.install();
    });

    test('initialize installs bundled catalog', () async {
      final store = TransitCatalogStore();
      await store.initialize();

      expect(store.isInitialized, isTrue);
      expect(store.activeManifest.catalogVersion, TransitCatalogBundled.catalogVersion);
      expect(TransitCatalogRegistry.agencies, isNotEmpty);
    });

    test('refreshIfStale applies newer remote manifest', () async {
      final remote = TransitCatalogManifest(
        catalogVersion: TransitCatalogBundled.catalogVersion + 1,
        schemaVersion: TransitCatalogManifest.supportedSchemaVersion,
        minAppVersion: '1.0.0',
        countries: TransitCatalogBundled.countries,
        defaultRegionByCountry: const {
          'Canada': 'Ontario',
          'United States': 'New York',
        },
        agencies: TransitCatalogBundled.agencies,
      );

      final store = TransitCatalogStore(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(remote.toJson()), 200),
        ),
        refreshInterval: Duration.zero,
      );
      await store.initialize();

      final updated = await store.refreshIfStale(force: true);

      expect(updated, isTrue);
      expect(store.activeManifest.catalogVersion, remote.catalogVersion);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('transit_catalog_cache_version'), remote.catalogVersion);
    });

    test('initialize skips cached manifest with incompatible minAppVersion',
        () async {
      final incompatible = TransitCatalogManifest(
        catalogVersion: TransitCatalogBundled.catalogVersion + 10,
        schemaVersion: TransitCatalogManifest.supportedSchemaVersion,
        minAppVersion: '99.0.0',
        countries: TransitCatalogBundled.countries,
        defaultRegionByCountry: const {
          'Canada': 'Ontario',
          'United States': 'New York',
        },
        agencies: TransitCatalogBundled.agencies,
      );

      SharedPreferences.setMockInitialValues({
        'transit_catalog_cache_json': jsonEncode(incompatible.toJson()),
      });

      final store = TransitCatalogStore();
      await store.initialize();

      expect(
        store.activeManifest.catalogVersion,
        TransitCatalogBundled.catalogVersion,
      );
    });

    test('refreshIfStale does not record refresh time on fetch failure',
        () async {
      final store = TransitCatalogStore(
        httpClient: MockClient((_) async => throw Exception('offline')),
        refreshInterval: Duration.zero,
      );
      await store.initialize();

      final updated = await store.refreshIfStale(force: true);

      expect(updated, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('transit_catalog_last_refresh_ms'), isNull);
    });

    test('refreshIfStale ignores incompatible minAppVersion', () async {
      final remote = TransitCatalogManifest(
        catalogVersion: TransitCatalogBundled.catalogVersion + 1,
        schemaVersion: TransitCatalogManifest.supportedSchemaVersion,
        minAppVersion: '99.0.0',
        countries: TransitCatalogBundled.countries,
        defaultRegionByCountry: const {
          'Canada': 'Ontario',
          'United States': 'New York',
        },
        agencies: TransitCatalogBundled.agencies,
      );

      final store = TransitCatalogStore(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(remote.toJson()), 200),
        ),
        refreshInterval: Duration.zero,
      );
      await store.initialize();

      final updated = await store.refreshIfStale(force: true);

      expect(updated, isFalse);
      expect(
        store.activeManifest.catalogVersion,
        TransitCatalogBundled.catalogVersion,
      );
    });
  });
}
