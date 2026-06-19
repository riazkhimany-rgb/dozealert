class GtfsFeedInfo {
  const GtfsFeedInfo({
    required this.feedId,
    required this.feedName,
    required this.agencyCount,
    required this.routeCount,
    required this.stopCount,
    required this.lastUpdated,
    this.sourceFileName,
  });

  final String feedId;
  final String feedName;
  final int agencyCount;
  final int routeCount;
  final int stopCount;
  final DateTime lastUpdated;
  final String? sourceFileName;

  factory GtfsFeedInfo.fromJson(Map<String, dynamic> json) {
    return GtfsFeedInfo(
      feedId: json['feedId'] as String,
      feedName: json['feedName'] as String,
      agencyCount: json['agencyCount'] as int,
      routeCount: json['routeCount'] as int,
      stopCount: json['stopCount'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      sourceFileName: json['sourceFileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedId': feedId,
      'feedName': feedName,
      'agencyCount': agencyCount,
      'routeCount': routeCount,
      'stopCount': stopCount,
      'lastUpdated': lastUpdated.toIso8601String(),
      'sourceFileName': sourceFileName,
    };
  }
}
