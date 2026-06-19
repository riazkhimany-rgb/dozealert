class TransitPreferences {
  const TransitPreferences({
    this.country = 'Canada',
    this.transitSystem = 'GO Transit',
    this.defaultLine = 'Lakeshore West',
  });

  final String country;
  final String transitSystem;
  final String defaultLine;

  static const defaults = TransitPreferences();

  TransitPreferences copyWith({
    String? country,
    String? transitSystem,
    String? defaultLine,
  }) {
    return TransitPreferences(
      country: country ?? this.country,
      transitSystem: transitSystem ?? this.transitSystem,
      defaultLine: defaultLine ?? this.defaultLine,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitPreferences &&
            other.country == country &&
            other.transitSystem == transitSystem &&
            other.defaultLine == defaultLine;
  }

  @override
  int get hashCode => Object.hash(country, transitSystem, defaultLine);
}
