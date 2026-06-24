import 'transit_vehicle_type.dart';

enum GtfsFeedStatus {
  notDownloaded,
  downloaded,
  downloading,
  updating,
  error,
}

/// How the user is expected to obtain GTFS data for a feed.
enum TransitDataAccessMode {
  inAppDownload,
  manualImport,
}

extension TransitDataAccessModeX on TransitDataAccessMode {
  String get label {
    return switch (this) {
      TransitDataAccessMode.inAppDownload => 'In-app download',
      TransitDataAccessMode.manualImport => 'Manual import',
    };
  }

  String get description {
    return switch (this) {
      TransitDataAccessMode.inAppDownload =>
        'Download or update directly from Transit Data.',
      TransitDataAccessMode.manualImport =>
        'Download from the agency open data page, then use Import GTFS Zip.',
    };
  }
}

extension GtfsFeedStatusX on GtfsFeedStatus {
  String get label {
    return switch (this) {
      GtfsFeedStatus.notDownloaded => 'Not downloaded',
      GtfsFeedStatus.downloaded => 'Downloaded',
      GtfsFeedStatus.downloading => 'Downloading…',
      GtfsFeedStatus.updating => 'Updating…',
      GtfsFeedStatus.error => 'Error',
    };
  }
}

class GtfsFeedInfo {
  const GtfsFeedInfo({
    required this.feedId,
    required this.agencyName,
    required this.province,
    required this.vehicleTypes,
    this.downloadUrl,
    this.supportsRealtime = false,
    this.openDataPageUrl,
    this.openDataPageLabel,
    this.requiresUserAcknowledgement = false,
    this.acknowledgementMessage,
    this.licenseUrl,
    this.attributionText,
    this.agencyCount = 0,
    this.routeCount = 0,
    this.stopCount = 0,
    this.lastUpdated,
    this.sourceFileName,
    this.status = GtfsFeedStatus.notDownloaded,
    this.errorMessage,
  });

  final String feedId;
  final String agencyName;
  final String province;
  final List<TransitVehicleType> vehicleTypes;
  final String? downloadUrl;
  final bool supportsRealtime;
  final String? openDataPageUrl;
  final String? openDataPageLabel;
  final bool requiresUserAcknowledgement;
  final String? acknowledgementMessage;
  final String? licenseUrl;
  final String? attributionText;
  final int agencyCount;
  final int routeCount;
  final int stopCount;
  final DateTime? lastUpdated;
  final String? sourceFileName;
  final GtfsFeedStatus status;
  final String? errorMessage;

  /// Legacy alias used by older cache entries.
  String get feedName => agencyName;

  TransitVehicleType get primaryVehicleType =>
      vehicleTypes.isNotEmpty ? vehicleTypes.first : TransitVehicleType.bus;

  String get vehicleTypesLabel =>
      vehicleTypes.map((type) => type.label).join(', ');

  bool get hasDirectDownload =>
      downloadUrl != null && downloadUrl!.trim().isNotEmpty;

  bool get hasOpenDataPage =>
      openDataPageUrl != null && openDataPageUrl!.trim().isNotEmpty;

  bool get isDownloaded =>
      status == GtfsFeedStatus.downloaded ||
      status == GtfsFeedStatus.updating ||
      (stopCount > 0 && lastUpdated != null);

  TransitDataAccessMode get dataAccessMode {
    if (requiresUserAcknowledgement ||
        (!hasDirectDownload && hasOpenDataPage)) {
      return TransitDataAccessMode.manualImport;
    }
    if (hasDirectDownload) {
      return TransitDataAccessMode.inAppDownload;
    }
    return TransitDataAccessMode.manualImport;
  }

  String get resolvedAttribution =>
      attributionText?.trim().isNotEmpty == true
          ? attributionText!.trim()
          : 'Transit schedule and stop data provided by $agencyName.';

  String? get resolvedLicenseUrl {
    final license = licenseUrl?.trim();
    if (license != null && license.isNotEmpty) {
      return license;
    }
    return hasOpenDataPage ? openDataPageUrl : null;
  }

  GtfsFeedInfo copyWith({
    String? feedId,
    String? agencyName,
    String? province,
    List<TransitVehicleType>? vehicleTypes,
    String? downloadUrl,
    bool? supportsRealtime,
    String? openDataPageUrl,
    String? openDataPageLabel,
    bool? requiresUserAcknowledgement,
    String? acknowledgementMessage,
    String? licenseUrl,
    String? attributionText,
    int? agencyCount,
    int? routeCount,
    int? stopCount,
    DateTime? lastUpdated,
    String? sourceFileName,
    GtfsFeedStatus? status,
    String? errorMessage,
  }) {
    return GtfsFeedInfo(
      feedId: feedId ?? this.feedId,
      agencyName: agencyName ?? this.agencyName,
      province: province ?? this.province,
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      supportsRealtime: supportsRealtime ?? this.supportsRealtime,
      openDataPageUrl: openDataPageUrl ?? this.openDataPageUrl,
      openDataPageLabel: openDataPageLabel ?? this.openDataPageLabel,
      requiresUserAcknowledgement:
          requiresUserAcknowledgement ?? this.requiresUserAcknowledgement,
      acknowledgementMessage:
          acknowledgementMessage ?? this.acknowledgementMessage,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      attributionText: attributionText ?? this.attributionText,
      agencyCount: agencyCount ?? this.agencyCount,
      routeCount: routeCount ?? this.routeCount,
      stopCount: stopCount ?? this.stopCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory GtfsFeedInfo.fromJson(Map<String, dynamic> json) {
    final agencyName =
        json['agencyName'] as String? ?? json['feedName'] as String? ?? '';
    final vehicleTypes = json['vehicleTypes'] != null
        ? TransitVehicleTypeX.listFromJson(json['vehicleTypes'])
        : TransitVehicleTypeX.listFromJson(json['vehicleType']);

    return GtfsFeedInfo(
      feedId: json['feedId'] as String,
      agencyName: agencyName,
      province: json['province'] as String? ?? 'Ontario',
      vehicleTypes: vehicleTypes,
      downloadUrl: json['downloadUrl'] as String?,
      supportsRealtime: json['supportsRealtime'] as bool? ?? false,
      openDataPageUrl: json['openDataPageUrl'] as String?,
      openDataPageLabel: json['openDataPageLabel'] as String?,
      requiresUserAcknowledgement:
          json['requiresUserAcknowledgement'] as bool? ?? false,
      acknowledgementMessage: json['acknowledgementMessage'] as String?,
      licenseUrl: json['licenseUrl'] as String?,
      attributionText: json['attributionText'] as String?,
      agencyCount: json['agencyCount'] as int? ?? 0,
      routeCount: json['routeCount'] as int? ?? 0,
      stopCount: json['stopCount'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
      sourceFileName: json['sourceFileName'] as String?,
      status: GtfsFeedStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => GtfsFeedStatus.downloaded,
      ),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedId': feedId,
      'agencyName': agencyName,
      'feedName': agencyName,
      'province': province,
      'vehicleTypes': vehicleTypes.map((type) => type.name).toList(),
      'downloadUrl': downloadUrl,
      'supportsRealtime': supportsRealtime,
      'openDataPageUrl': openDataPageUrl,
      'openDataPageLabel': openDataPageLabel,
      'requiresUserAcknowledgement': requiresUserAcknowledgement,
      'acknowledgementMessage': acknowledgementMessage,
      'licenseUrl': licenseUrl,
      'attributionText': attributionText,
      'agencyCount': agencyCount,
      'routeCount': routeCount,
      'stopCount': stopCount,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'sourceFileName': sourceFileName,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }
}
