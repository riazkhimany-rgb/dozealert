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
    this.generatedAt,
  });

  static const supportedSchemaVersion = 1;

  final int catalogVersion;
  final int schemaVersion;
  final String minAppVersion;
  final DateTime? generatedAt;
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
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
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

  TransitCatalogManifest copyWith({
    int? catalogVersion,
    int? schemaVersion,
    String? minAppVersion,
    DateTime? generatedAt,
    List<String>? countries,
    Map<String, String>? defaultRegionByCountry,
    List<TransitCatalogAgency>? agencies,
  }) {
    return TransitCatalogManifest(
      catalogVersion: catalogVersion ?? this.catalogVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      countries: countries ?? this.countries,
      defaultRegionByCountry:
          defaultRegionByCountry ?? this.defaultRegionByCountry,
      agencies: agencies ?? this.agencies,
    );
  }

  /// Immutable catalog serialization (bundled asset, remote JSON, device cache).
  Map<String, dynamic> toCatalogJson() {
    return {
      'catalogVersion': catalogVersion,
      'schemaVersion': schemaVersion,
      'minAppVersion': minAppVersion,
      if (generatedAt != null) 'generatedAt': generatedAt!.toUtc().toIso8601String(),
      'countries': countries,
      'defaultRegionByCountry': defaultRegionByCountry,
      'agencies': agencies.map((agency) => agency.toCatalogJson()).toList(),
    };
  }

  Map<String, dynamic> toJson() => toCatalogJson();
}
