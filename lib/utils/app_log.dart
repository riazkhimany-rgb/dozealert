import 'package:flutter/foundation.dart';

/// Debug-only logging. Release builds omit all output.
abstract final class AppLog {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint(message);
      if (error != null) {
        debugPrint('$error');
      }
      if (stackTrace != null) {
        debugPrint('$stackTrace');
      }
    }
  }
}
