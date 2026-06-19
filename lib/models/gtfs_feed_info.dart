import 'transit_vehicle_type.dart';

enum GtfsFeedStatus {
  notDownloaded,
  downloaded,
  downloading,
  updating,
  error,
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
    required this.vehicleType,
    this.downloadUrl,
    this.supportsRealtime = false,
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
  final String? downloadUrl;
  final TransitVehicleType vehicleType;
  final bool supportsRealtime;
  final int agencyCount;
  final int routeCount;
  final int stopCount;
  final DateTime? lastUpdated;
  final String? sourceFileName;
  final GtfsFeedStatus status;
  final String? errorMessage;

  /// Legacy alias used by older cache entries.
  String get feedName => agencyName;

  bool get isDownloaded =>
      status == GtfsFeedStatus.downloaded ||
      status == GtfsFeedStatus.updating ||
      (stopCount > 0 && lastUpdated != null);

  GtfsFeedInfo copyWith({
    String? feedId,
    String? agencyName,
    String? downloadUrl,
    TransitVehicleType? vehicleType,
    bool? supportsRealtime,
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
      downloadUrl: downloadUrl ?? this.downloadUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      supportsRealtime: supportsRealtime ?? this.supportsRealtime,
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
    return GtfsFeedInfo(
      feedId: json['feedId'] as String,
      agencyName: agencyName,
      downloadUrl: json['downloadUrl'] as String?,
      vehicleType: TransitVehicleTypeX.fromName(json['vehicleType'] as String?),
      supportsRealtime: json['supportsRealtime'] as bool? ?? false,
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
      'downloadUrl': downloadUrl,
      'vehicleType': vehicleType.name,
      'supportsRealtime': supportsRealtime,
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
