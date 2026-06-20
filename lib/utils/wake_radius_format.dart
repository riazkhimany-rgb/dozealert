abstract final class WakeRadiusFormat {
  static String alertDescription(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      final label = km == km.roundToDouble()
          ? km.toStringAsFixed(0)
          : km.toStringAsFixed(1);
      return 'Alert within $label km';
    }

    return 'Alert within ${meters}m';
  }
}
