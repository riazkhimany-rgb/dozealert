import '../cache/gtfs_cache_store.dart';
import '../models/gtfs_parse_schema.dart';

abstract final class GtfsCacheMigration {
  static final _patternStopIdPattern = RegExp(r':(d\d+|h[a-z0-9_]+):s\d+$');

  static bool isStale(GtfsCachedFeed feed) {
    if (feed.stops.isEmpty) {
      return false;
    }
    if (feed.info.parseSchemaVersion >= GtfsParseSchema.current) {
      return false;
    }
    return true;
  }

  static bool stopHasPatternKey(String stopId) {
    return _patternStopIdPattern.hasMatch(stopId);
  }

  @Deprecated('Use stopHasPatternKey')
  static bool stopHasDirectionId(String stopId) => stopHasPatternKey(stopId);
}
