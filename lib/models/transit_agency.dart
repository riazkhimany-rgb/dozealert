class TransitAgency {
  const TransitAgency({
    required this.agencyId,
    required this.agencyName,
    required this.country,
    required this.city,
    this.supportsRealtime = false,
  });

  final String agencyId;
  final String agencyName;
  final String country;
  final String city;
  final bool supportsRealtime;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransitAgency &&
            other.agencyId == agencyId &&
            other.agencyName == agencyName &&
            other.country == country &&
            other.city == city &&
            other.supportsRealtime == supportsRealtime;
  }

  @override
  int get hashCode =>
      Object.hash(agencyId, agencyName, country, city, supportsRealtime);
}
