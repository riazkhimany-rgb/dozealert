/// Compares dotted version names (e.g. `1.1.0`), ignoring build suffixes.
abstract final class AppVersionCompare {
  static int compare(String left, String right) {
    final a = _parts(left);
    final b = _parts(right);
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final av = index < a.length ? a[index] : 0;
      final bv = index < b.length ? b[index] : 0;
      if (av != bv) {
        return av.compareTo(bv);
      }
    }
    return 0;
  }

  static bool isAtLeast(String appVersion, String minimum) {
    return compare(appVersion, minimum) >= 0;
  }

  static List<int> _parts(String version) {
    final normalized = version.split('+').first.trim();
    if (normalized.isEmpty) {
      return const [0];
    }
    return normalized
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList(growable: false);
  }
}
