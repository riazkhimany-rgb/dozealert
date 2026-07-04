import 'transit_route.dart';

class TransitLineOption {
  const TransitLineOption({
    required this.lineName,
    required this.displayLabel,
    this.subtitle,
  });

  /// Stored in preferences and used for route lookup.
  final String lineName;

  /// Primary label shown in pickers (often the route number).
  final String displayLabel;

  /// Secondary detail such as the route long name.
  final String? subtitle;

  String get singleLineLabel {
    if (subtitle == null || subtitle!.isEmpty) {
      return displayLabel;
    }
    return '$displayLabel · $subtitle';
  }

  /// Route code plus long name, e.g. `LW - Lakeshore West`.
  String get shortDashLongLabel {
    if (subtitle != null &&
        subtitle!.isNotEmpty &&
        subtitle != displayLabel) {
      return '$displayLabel - $subtitle';
    }
    return displayLabel;
  }

  factory TransitLineOption.fromRoute(TransitRoute route) {
    final shortName = route.routeShortName?.trim();
    final lineName = route.lineName;
    final longName = route.routeName.trim();

    if (shortName != null &&
        shortName.isNotEmpty &&
        longName.isNotEmpty &&
        shortName != longName) {
      return TransitLineOption(
        lineName: lineName,
        displayLabel: shortName,
        subtitle: longName,
      );
    }

    return TransitLineOption(
      lineName: lineName,
      displayLabel: lineName,
    );
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return lineName.toLowerCase().contains(normalized) ||
        displayLabel.toLowerCase().contains(normalized) ||
        (subtitle?.toLowerCase().contains(normalized) ?? false);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitLineOption &&
            other.lineName == lineName &&
            other.displayLabel == displayLabel &&
            other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(lineName, displayLabel, subtitle);
}
