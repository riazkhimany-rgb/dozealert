/// GTFS cache format versions. Bump [current] when stop parsing changes.
abstract final class GtfsParseSchema {
  /// Legacy parser merged all trips into one stop order per route.
  static const legacy = 1;

  /// Direction-aware patterns (`:d{direction}:s{sequence}` stop ids).
  static const directionPatterns = 2;

  /// Normalized stop names (direction suffixes stripped for matching/display).
  static const normalizedStopNames = 3;

  /// Headsign grouping tiebreaker, parent_station resolution, pattern keys in stop ids.
  static const headsignAndParentStations = 4;

  /// GTFS shapes.txt geometry per route pattern (optional).
  static const routeShapes = 6;

  static const current = routeShapes;
}
