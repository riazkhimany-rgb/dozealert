import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(activeKey);
    await prefs.remove(stateKey);
    await prefs.setBool(arrivalTriggeredKey, false);
  }
}
