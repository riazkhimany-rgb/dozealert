import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/background_transit_pattern.dart';
import '../models/monitoring_state.dart';

class MonitoringSession {
  const MonitoringSession({
    required this.isActive,
    required this.state,
    required this.radiusMeters,
  });

  final bool isActive;
  final MonitoringState state;
  final int radiusMeters;
}

class MonitoringStorageService {
  static const activeKey = 'monitoring_active';
  static const stateKey = 'monitoring_state_index';
  static const radiusKey = 'monitoring_radius_meters';
  static const arrivalTriggeredKey = 'monitoring_arrival_triggered';
  static const monitoringStartedAtKey = 'monitoring_started_at_ms';
  static const transitOnRouteKey = 'transit_on_route_active';

  static const transitStopsRemainingKey = 'transit_stops_remaining';
  static const transitWakeStopCountKey = 'transit_wake_stop_count';
  static const transitDirectionLockedKey = 'transit_direction_locked';
  static const transitHasTripConcernKey = 'transit_has_trip_concern';
  static const transitActiveKey = 'transit_active_snapshot';
  static const transitAlarmHeadlineKey = 'transit_alarm_headline';
  static const transitAlarmBodyKey = 'transit_alarm_body';
  static const transitAlarmTtsKey = 'transit_alarm_tts';
  static const transitAlarmStopNameKey = 'transit_alarm_stop_name';
  static const transitAlarmSublineKey = 'transit_alarm_subline';
  static const transitPatternSnapshotKey = 'transit_pattern_snapshot_json';
  static const transitStabilizedStopSequenceKey =
      'transit_stabilized_stop_sequence';
  static const transitLineLabelKey = 'transit_line_label';

  Future<void> saveSession({
    required bool isActive,
    required MonitoringState state,
    required int radiusMeters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(activeKey, isActive);
    await prefs.setInt(stateKey, state.index);
    await prefs.setInt(radiusKey, radiusMeters);
  }

  Future<void> saveRadius(int radiusMeters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(radiusKey, radiusMeters);
  }

  Future<int> loadRadiusMeters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(radiusKey) ?? 1000;
  }

  Future<MonitoringSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(activeKey);
    if (isActive == null) {
      return null;
    }

    final stateIndex = prefs.getInt(stateKey);
    final radiusMeters = prefs.getInt(radiusKey) ?? 1000;

    return MonitoringSession(
      isActive: isActive,
      state: stateIndex != null && stateIndex < MonitoringState.values.length
          ? MonitoringState.values[stateIndex]
          : MonitoringState.idle,
      radiusMeters: radiusMeters,
    );
  }

  Future<bool> isMonitoringActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(activeKey) ?? false;
  }

  Future<bool> isArrivalTriggered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(arrivalTriggeredKey) ?? false;
  }

  Future<void> setArrivalTriggered(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(arrivalTriggeredKey, value);
  }

  Future<void> markMonitoringStarted([DateTime? startedAt]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      monitoringStartedAtKey,
      (startedAt ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  Future<DateTime?> loadMonitoringStartedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(monitoringStartedAtKey);
    if (timestamp == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(activeKey);
    await prefs.remove(stateKey);
    await prefs.remove(monitoringStartedAtKey);
    await prefs.setBool(arrivalTriggeredKey, false);
    await prefs.setBool(transitOnRouteKey, false);
    await clearTransitBackgroundSnapshot();
  }

  Future<void> setTransitOnRouteActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(transitOnRouteKey, value);
  }

  Future<bool> isTransitOnRouteActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(transitOnRouteKey) ?? false;
  }

  Future<void> saveTransitBackgroundSnapshot({
    required bool transitActive,
    required int stopsRemaining,
    required int wakeStopCount,
    required bool directionLocked,
    required bool hasTripConcern,
    required String alarmHeadline,
    required String alarmBody,
    required String alarmTts,
    required String alarmStopName,
    required String alarmSubline,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(transitActiveKey, transitActive);
    await prefs.setInt(transitStopsRemainingKey, stopsRemaining);
    await prefs.setInt(transitWakeStopCountKey, wakeStopCount);
    await prefs.setBool(transitDirectionLockedKey, directionLocked);
    await prefs.setBool(transitHasTripConcernKey, hasTripConcern);
    await prefs.setString(transitAlarmHeadlineKey, alarmHeadline);
    await prefs.setString(transitAlarmBodyKey, alarmBody);
    await prefs.setString(transitAlarmTtsKey, alarmTts);
    await prefs.setString(transitAlarmStopNameKey, alarmStopName);
    await prefs.setString(transitAlarmSublineKey, alarmSubline);
  }

  Future<void> clearTransitBackgroundSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(transitActiveKey);
    await prefs.remove(transitStopsRemainingKey);
    await prefs.remove(transitWakeStopCountKey);
    await prefs.remove(transitDirectionLockedKey);
    await prefs.remove(transitHasTripConcernKey);
    await prefs.remove(transitAlarmHeadlineKey);
    await prefs.remove(transitAlarmBodyKey);
    await prefs.remove(transitAlarmTtsKey);
    await prefs.remove(transitAlarmStopNameKey);
    await prefs.remove(transitAlarmSublineKey);
    await prefs.remove(transitPatternSnapshotKey);
    await prefs.remove(transitStabilizedStopSequenceKey);
    await prefs.remove(transitLineLabelKey);
  }

  Future<void> saveBackgroundTransitPattern(
    BackgroundTransitPattern pattern,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      transitPatternSnapshotKey,
      jsonEncode(pattern.toJson()),
    );
    await prefs.setInt(
      transitStabilizedStopSequenceKey,
      pattern.stabilizedStopSequence,
    );
    await prefs.setString(transitLineLabelKey, pattern.lineLabel);
  }

  Future<BackgroundTransitPattern?> loadBackgroundTransitPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(transitPatternSnapshotKey);
    final pattern = BackgroundTransitPattern.fromJsonString(raw);
    if (pattern == null) {
      return null;
    }

    final stabilizedSequence =
        prefs.getInt(transitStabilizedStopSequenceKey) ?? -1;
    if (stabilizedSequence > 0 &&
        stabilizedSequence != pattern.stabilizedStopSequence) {
      return pattern.copyWith(stabilizedStopSequence: stabilizedSequence);
    }
    return pattern;
  }

  Future<void> saveStabilizedStopSequence(int sequence) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(transitStabilizedStopSequenceKey, sequence);
  }
}
