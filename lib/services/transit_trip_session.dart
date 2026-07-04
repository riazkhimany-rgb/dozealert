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

  /// Pattern key awaiting GPS confirmation before [isDirectionLocked] is true.
  String? get pendingPatternKey => _pendingPatternKey;

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
  ///
  /// The lock is *self-correcting*: even after a direction is locked, a
  /// different direction inferred by GPS for [lockFixCount] consecutive fixes
  /// re-locks onto the new direction. This recovers from an early wrong lock
  /// (e.g. a destination-only seed that guessed the opposite direction on a
  /// bidirectional route) instead of staying wrong for the whole trip.
  String? updateAndGetPatternKey({
    required String routeId,
    required String destinationKey,
    required String? inferredPatternKey,
  }) {
    if (_routeId != routeId || _destinationKey != destinationKey) {
      _beginSession(routeId, destinationKey);
    }

    final current = _lockedPatternKey ?? _pendingPatternKey;

    if (inferredPatternKey == null || inferredPatternKey.isEmpty) {
      return current;
    }

    // GPS agrees with the direction we are already using.
    if (inferredPatternKey == current) {
      if (_lockedPatternKey != null) {
        _pendingPatternKey = null;
        _pendingCount = 0;
        return _lockedPatternKey;
      }
      _pendingCount++;
      if (_pendingCount >= lockFixCount) {
        _lockedPatternKey = inferredPatternKey;
        _pendingPatternKey = null;
        _pendingCount = 0;
      }
      return _lockedPatternKey ?? _pendingPatternKey;
    }

    // GPS disagrees: build confidence in the alternative before switching.
    if (inferredPatternKey == _pendingPatternKey) {
      _pendingCount++;
    } else {
      _pendingPatternKey = inferredPatternKey;
      _pendingCount = 1;
    }

    if (_pendingCount >= lockFixCount) {
      _lockedPatternKey = inferredPatternKey;
      _pendingPatternKey = null;
      _pendingCount = 0;
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
