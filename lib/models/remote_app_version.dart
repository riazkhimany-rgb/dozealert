class RemoteAppVersion {
  const RemoteAppVersion({
    required this.version,
    required this.build,
    this.label,
  });

  final String version;
  final int build;
  final String? label;

  String get displayLabel {
    if (label != null && label!.isNotEmpty) {
      return label!;
    }
    return '$version+$build';
  }

  factory RemoteAppVersion.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as String? ?? '0.0.0';
    final build = _parseBuild(json['build']);
    return RemoteAppVersion(
      version: version,
      build: build,
      label: json['label'] as String?,
    );
  }

  static int _parseBuild(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  bool isNewerThan(int currentBuild) => build > currentBuild;
}
