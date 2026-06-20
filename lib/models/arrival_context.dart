class ArrivalContext {
  const ArrivalContext({
    required this.destinationName,
    required this.usedTransitMode,
    this.detailMessage,
    this.distanceKm,
    this.stopsRemaining,
  });

  final String destinationName;
  final bool usedTransitMode;
  final String? detailMessage;
  final double? distanceKm;
  final int? stopsRemaining;
}
