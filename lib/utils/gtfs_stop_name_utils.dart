/// Normalizes GTFS stop names for display and matching.
abstract final class GtfsStopNameUtils {
  static final _directionSuffixPattern = RegExp(
    r'\s*[-–—]?\s*(Northbound|Southbound|Eastbound|Westbound|NB|SB|EB|WB)\s*$',
    caseSensitive: false,
  );

  static final _platformSuffixPattern = RegExp(
    r'\s*[-–—]\s*(Northbound|Southbound|Eastbound|Westbound|Subway|Bus|Streetcar|LRT)\s+Platform\s*$',
    caseSensitive: false,
  );

  static final _genericPlatformSuffixPattern = RegExp(
    r'\s*[-–—]\s*Platform\s*$',
    caseSensitive: false,
  );

  /// User-facing station name with platform/direction qualifiers removed.
  static String stationDisplayName(String raw) => normalize(raw);

  static String normalize(String raw) {
    var name = raw.trim();
    var changed = true;
    while (changed) {
      changed = false;
      for (final pattern in [
        _platformSuffixPattern,
        _directionSuffixPattern,
        _genericPlatformSuffixPattern,
      ]) {
        if (pattern.hasMatch(name)) {
          name = name.replaceFirst(pattern, '').trim();
          changed = true;
        }
      }
    }
    return name;
  }

  static bool namesMatch(String a, String b) {
    return normalize(a).toLowerCase() == normalize(b).toLowerCase();
  }
}
