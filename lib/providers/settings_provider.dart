import 'package:flutter/material.dart';

import '../models/alarm_sound_mode.dart';
import '../models/transit_mode_wake_setting.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settingsService);

  final SettingsService _settingsService;

  bool get testModeEnabled => _settingsService.settings.testModeEnabled;
  bool get transitModeEnabled => _settingsService.settings.transitModeEnabled;
  TransitModeWakeSetting get transitModeWake =>
      _settingsService.settings.transitModeWake;
  AlarmSoundMode get alarmSoundMode => _settingsService.settings.alarmSoundMode;
  bool get alwaysPlayAlarmSound => _settingsService.settings.alwaysPlayAlarmSound;

  Future<void> setTestModeEnabled(bool enabled) async {
    if (enabled == testModeEnabled) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(testModeEnabled: enabled),
    );
    notifyListeners();
  }

  Future<void> setTransitModeEnabled(bool enabled) async {
    if (enabled == transitModeEnabled) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(transitModeEnabled: enabled),
    );
    notifyListeners();
  }

  Future<void> setTransitModeWake(TransitModeWakeSetting wakeSetting) async {
    if (wakeSetting == transitModeWake) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(transitModeWake: wakeSetting),
    );
    notifyListeners();
  }

  Future<void> setAlarmSoundMode(AlarmSoundMode mode) async {
    if (mode == alarmSoundMode) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(alarmSoundMode: mode),
    );
    notifyListeners();
  }
}
