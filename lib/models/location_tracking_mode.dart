/// How aggressively the fused location provider should run.
enum LocationTrackingMode {
  /// Low-rate fixes while a destination is selected but monitoring has not started.
  prewarm,

  /// Navigation-grade fixes during an active monitoring session.
  monitoring,
}
