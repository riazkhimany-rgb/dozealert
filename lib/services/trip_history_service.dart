import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_history_entry.dart';

class TripHistoryService {
  static const _historyKey = 'trip_history_entries';
  static const _activeTripIdKey = 'trip_history_active_id';
  static const _maxEntries = 50;

  String? _activeTripId;

  Future<void> loadActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();
    _activeTripId = prefs.getString(_activeTripIdKey);
  }

  Future<List<TripHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (entry) =>
                TripHistoryEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false);
    } catch (error) {
      debugPrint('TripHistoryService: failed to load history: $error');
      return const [];
    }
  }

  Future<void> startTrip(String destination) async {
    final entry = TripHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      destination: destination,
      tripStart: DateTime.now(),
    );

    final history = await loadHistory();
    final updated = [entry, ...history].take(_maxEntries).toList();
    await _saveHistory(updated);

    _activeTripId = entry.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTripIdKey, entry.id);

    debugPrint('TripHistoryService: started trip to $destination');
  }

  Future<void> recordAlarmTriggered() async {
    await _updateActiveTrip(
      (entry) => entry.copyWith(alarmTriggered: DateTime.now()),
    );
  }

  Future<void> recordAlarmDismissed() async {
    await _updateActiveTrip(
      (entry) => entry.copyWith(
        alarmDismissed: DateTime.now(),
        tripEnd: DateTime.now(),
      ),
    );
    await _clearActiveTrip();
  }

  Future<void> recordMissedTrip() async {
    await _updateActiveTrip(
      (entry) => entry.copyWith(
        missedTrip: true,
        tripEnd: DateTime.now(),
      ),
    );
    await _clearActiveTrip();
  }

  Future<void> endTrip({bool missed = false}) async {
    if (missed) {
      await recordMissedTrip();
      return;
    }

    await _updateActiveTrip(
      (entry) => entry.copyWith(tripEnd: DateTime.now()),
    );
    await _clearActiveTrip();
  }

  Future<void> _updateActiveTrip(
    TripHistoryEntry Function(TripHistoryEntry entry) transform,
  ) async {
    if (_activeTripId == null) {
      await loadActiveTripId();
    }

    final activeId = _activeTripId;
    if (activeId == null) {
      return;
    }

    final history = await loadHistory();
    final index = history.indexWhere((entry) => entry.id == activeId);
    if (index == -1) {
      return;
    }

    final updatedHistory = [...history];
    updatedHistory[index] = transform(updatedHistory[index]);
    await _saveHistory(updatedHistory);
  }

  Future<void> _clearActiveTrip() async {
    _activeTripId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTripIdKey);
  }

  Future<void> _saveHistory(List<TripHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}
