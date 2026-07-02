/// Per-monitoring-session state: locks trip direction after consistent GPS fixes.
class TransitTripSession {
  static const lockFixCount = 3;

  String? _routeId;
  String? _destinationKey;
  String? _lockedPatternKey;
  String? _pendingPatternKey;
  int _pendingCount = 0;
  bool _seeded = false;

  String? get lockedPatternKey => _lockedPatternKey;

  bool get isDirectionLocked => _lockedPatternKey != null;

  bool get hasPendingDirection => _pendingPatternKey != null;

  bool get isSeeded => _seeded;

  void reset() {
    _routeId = null;
    _destinationKey = null;
    _lockedPatternKey = null;
    _pendingPatternKey = null;
    _pendingCount = 0;
    _seeded = false;
  }

  /// Seeds the direction from the user's destination pick (optionally with GPS).
  ///
  /// The seed is stored as *pending* rather than immediately locked so that the
  /// first confirming GPS fix promotes it to locked. If the inferred GPS
  /// direction disagrees (e.g. the seed was destination-only and the user is on
  /// a bidirectional bus route), the GPS pattern replaces the pending and the
  /// session converges to the correct direction within [lockFixCount] fixes.
  void seedPatternKey({
    required String routeId,
    required String destinationKey,
    required String patternKey,
  }) {
    if (patternKey.isEmpty) {
      return;
    }

    if (_routeId != routeId || _destinationKey != destinationKey) {
      _beginSession(routeId, destinationKey);
    }

    // Pending-only: one agreeing GPS fix locks it; a disagreeing fix resets it.
    _pendingPatternKey = patternKey;
    _pendingCount = lockFixCount - 1;
    _seeded = true;
  }

  /// Records [inferredPatternKey] from the current GPS fix.
  /// Returns the pattern key to use for [GtfsService.stopsForRoute].
  String? updateAndGetPatternKey({
    required String routeId,
    required String destinationKey,
    required String? inferredPatternKey,
  }) {
    if (_routeId != routeId || _destinationKey != destinationKey) {
      _beginSession(routeId, destinationKey);
    }

    if (_lockedPatternKey != null) {
      return _lockedPatternKey;
    }

    if (inferredPatternKey == null || inferredPatternKey.isEmpty) {
      return _pendingPatternKey;
    }

    if (inferredPatternKey == _pendingPatternKey) {
      _pendingCount++;
    } else {
      _pendingPatternKey = inferredPatternKey;
      _pendingCount = 1;
    }

    if (_pendingCount >= lockFixCount) {
      _lockedPatternKey = inferredPatternKey;
    }

    return _lockedPatternKey ?? _pendingPatternKey;
  }

  void _beginSession(String routeId, String destinationKey) {
    _routeId = routeId;
    _destinationKey = destinationKey;
    _lockedPatternKey = null;
    _pendingPatternKey = null;
    _pendingCount = 0;
    _seeded = false;
  }
}
