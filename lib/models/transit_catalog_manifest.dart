import '../data/transit_catalog_registry.dart';
import '../utils/app_version_compare.dart';
import 'transit_catalog_agency.dart';

/// Remote/bundled transit catalog envelope with versioning metadata.
class TransitCatalogManifest {
  const TransitCatalogManifest({
    required this.catalogVersion,
    required this.schemaVersion,
    required this.minAppVersion,
    required this.countries,
    required this.defaultRegionByCountry,
    required this.agencies,
  });

  static const supportedSchemaVersion = 1;

  final int catalogVersion;
  final int schemaVersion;
  final String minAppVersion;
  final List<String> countries;
  final Map<String, String> defaultRegionByCountry;
  final List<TransitCatalogAgency> agencies;

  bool isCompatibleWithApp(String appVersion) {
    if (schemaVersion > supportedSchemaVersion) {
      return false;
    }
    return AppVersionCompare.isAtLeast(appVersion, minAppVersion);
  }

  void install() {
    TransitCatalogRegistry.install(this);
  }

  factory TransitCatalogManifest.fromJson(Map<String, dynamic> json) {
    final agenciesJson = json['agencies'];
    return TransitCatalogManifest(
      catalogVersion: json['catalogVersion'] as int? ?? 0,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      minAppVersion: json['minAppVersion'] as String? ?? '1.0.0',
      countries: (json['countries'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      defaultRegionByCountry: Map<String, String>.from(
        json['defaultRegionByCountry'] as Map? ?? const {},
      ),
      agencies: agenciesJson is List
          ? agenciesJson
              .map(
                (entry) => TransitCatalogAgency.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catalogVersion': catalogVersion,
      'schemaVersion': schemaVersion,
      'minAppVersion': minAppVersion,
      'countries': countries,
      'defaultRegionByCountry': defaultRegionByCountry,
      'agencies': agencies.map((agency) => agency.toJson()).toList(),
    };
  }
}
