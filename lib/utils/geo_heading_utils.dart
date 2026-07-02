/// Shared GPS heading helpers for route matching.
abstract final class GeoHeadingUtils {
  static const minSpeedMpsForHeading = 2.5;

  static bool shouldUseHeading(double? headingDegrees, double? speedMps) {
    if (headingDegrees == null || headingDegrees < 0) {
      return false;
    }
    return (speedMps ?? 0) >= minSpeedMpsForHeading;
  }

  static double headingDeltaDegrees(double bearing, double heading) {
    var delta = (bearing - heading).abs() % 360;
    if (delta > 180) {
      delta = 360 - delta;
    }
    return delta;
  }
}
