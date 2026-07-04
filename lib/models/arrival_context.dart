class ArrivalContext {
  const ArrivalContext({
    required this.destinationName,
    required this.usedTransitMode,
    this.headline,
    this.currentStopName,
    this.detailMessage,
    this.secondaryLine,
    this.wearSubline,
    this.distanceKm,
    this.stopsRemaining,
  });

  final String destinationName;
  final bool usedTransitMode;
  final String? headline;
  final String? currentStopName;
  final String? detailMessage;
  final String? secondaryLine;
  final String? wearSubline;
  final double? distanceKm;
  final int? stopsRemaining;
}
