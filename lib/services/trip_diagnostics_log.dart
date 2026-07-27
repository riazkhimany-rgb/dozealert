import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_log.dart';

/// Persistent breadcrumb trail for a trip, written so a locked-phone field test
/// produces evidence instead of recollection.
///
/// Entries survive process death, which matters because the interesting
/// failures happen while the screen is off and nobody can read a debug console.
class TripDiagnosticsLog {
  TripDiagnosticsLog._();

  static const _key = 'trip_diagnostics_entries';
  static const _maxEntries = 400;

  static final List<String> _entries = <String>[];
  static bool _loaded = false;
  static Future<void> _pendingWrite = Future<void>.value();

  static Future<void> record(String event, [Map<String, Object?>? data]) async {
    await _ensureLoaded();

    final buffer = StringBuffer()
      ..write(DateTime.now().toIso8601String())
      ..write(' | ')
      ..write(event);

    if (data != null && data.isNotEmpty) {
      final pairs = data.entries
          .where((entry) => entry.value != null)
          .map((entry) => '${entry.key}=${entry.value}')
          .join(' ');
      if (pairs.isNotEmpty) {
        buffer
          ..write(' | ')
          ..write(pairs);
      }
    }

    final line = buffer.toString();
    AppLog.d('TripDiagnostics: $line');

    _entries.add(line);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }

    _pendingWrite = _pendingWrite.then((_) => _flush());
    await _pendingWrite;
  }

  static Future<List<String>> entries() async {
    await _ensureLoaded();
    return List<String>.unmodifiable(_entries.reversed);
  }

  static Future<void> clear() async {
    _entries.clear();
    _loaded = true;
    await _flush();
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _entries.addAll(prefs.getStringList(_key) ?? const <String>[]);
    } catch (error) {
      AppLog.d('TripDiagnosticsLog: load failed: $error');
    }
  }

  static Future<void> _flush() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, List<String>.from(_entries));
    } catch (error) {
      AppLog.d('TripDiagnosticsLog: save failed: $error');
    }
  }
}
