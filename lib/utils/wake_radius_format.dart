abstract final class WakeRadiusFormat {
  static String _distanceLabel(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return km == km.roundToDouble()
          ? km.toStringAsFixed(0)
          : km.toStringAsFixed(1);
    }

    return '${meters}m';
  }

  static String alertDescription(int meters) {
    if (meters >= 1000) {
      return 'Alert within ${_distanceLabel(meters)} km';
    }

    return 'Alert within ${_distanceLabel(meters)}';
  }

  static String wakeByDescription(int meters) {
    if (meters >= 1000) {
      return 'Wake by ${_distanceLabel(meters)} km';
    }

    return 'Wake by ${_distanceLabel(meters)}';
  }
}
