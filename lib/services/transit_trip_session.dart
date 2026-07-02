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

  /// Locks direction immediately from the user's line/destination pick (no GPS).
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

    _lockedPatternKey = patternKey;
    _pendingPatternKey = patternKey;
    _pendingCount = lockFixCount;
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
  }
}
