class TransitPreferences {
  const TransitPreferences({
    this.country = 'Canada',
    this.region = 'Ontario',
    this.transitSystem = 'GO Transit',
    this.defaultLine = 'Lakeshore West',
  });

  final String country;
  final String region;
  final String transitSystem;
  final String defaultLine;

  static const defaults = TransitPreferences();

  TransitPreferences copyWith({
    String? country,
    String? region,
    String? transitSystem,
    String? defaultLine,
  }) {
    return TransitPreferences(
      country: country ?? this.country,
      region: region ?? this.region,
      transitSystem: transitSystem ?? this.transitSystem,
      defaultLine: defaultLine ?? this.defaultLine,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitPreferences &&
            other.country == country &&
            other.region == region &&
            other.transitSystem == transitSystem &&
            other.defaultLine == defaultLine;
  }

  @override
  int get hashCode =>
      Object.hash(country, region, transitSystem, defaultLine);
}
