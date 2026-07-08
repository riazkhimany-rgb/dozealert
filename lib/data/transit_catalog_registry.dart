import '../models/transit_catalog_agency.dart';
import '../models/transit_catalog_manifest.dart';

/// Active catalog snapshot used by [TransitCatalog] lookups.
abstract final class TransitCatalogRegistry {
  static TransitCatalogManifest? _manifest;

  static TransitCatalogManifest get instance {
    final manifest = _manifest;
    if (manifest == null) {
      throw StateError(
        'Transit catalog is not initialized. Call TransitCatalogStore.initialize() '
        'before using TransitCatalog.',
      );
    }
    return manifest;
  }

  static bool get isInitialized => _manifest != null;

  static List<TransitCatalogAgency> get agencies => instance.agencies;

  static List<String> get countries => instance.countries;

  static Map<String, String> get defaultRegionByCountry =>
      instance.defaultRegionByCountry;

  static int get catalogVersion => instance.catalogVersion;

  static void install(TransitCatalogManifest manifest) {
    _manifest = manifest;
  }

  static void resetForTesting(TransitCatalogManifest manifest) {
    _manifest = manifest;
  }

  static void clearForTesting() {
    _manifest = null;
  }
}
