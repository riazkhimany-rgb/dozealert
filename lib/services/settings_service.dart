import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm_sound_mode.dart';
import '../models/app_settings.dart';
import '../models/transit_mode_wake_setting.dart';

class SettingsService {
  static const _themeModeKey = 'theme_mode';
  static const _testModeKey = 'test_mode_enabled';
  static const _transitModeEnabledKey = 'transit_mode_enabled';
  static const _transitModeWakeKey = 'transit_mode_wake';
  static const _alarmSoundModeKey = 'alarm_sound_mode';
  static const _legacyTrainModeEnabledKey = 'train_mode_enabled';
  static const _legacyTrainModeWakeKey = 'train_mode_wake';

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey);
    final testModeEnabled = prefs.getBool(_testModeKey) ?? false;
    final transitModeEnabled = prefs.getBool(_transitModeEnabledKey) ??
        prefs.getBool(_legacyTrainModeEnabledKey) ??
        false;
    final transitModeWakeIndex = prefs.getInt(_transitModeWakeKey) ??
        prefs.getInt(_legacyTrainModeWakeKey);
    final alarmSoundModeIndex = prefs.getInt(_alarmSoundModeKey);

    _settings = AppSettings(
      themeMode: themeIndex != null && themeIndex < ThemeMode.values.length
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system,
      testModeEnabled: testModeEnabled,
      transitModeEnabled: transitModeEnabled,
      transitModeWake: TransitModeWakeSettingX.fromLegacyIndex(
        transitModeWakeIndex ??
            TransitModeWakeSetting.oneStopBefore.index,
      ),
      alarmSoundMode: AlarmSoundModeX.fromIndex(
        alarmSoundModeIndex ?? AlarmSoundMode.followDevice.index,
      ),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, settings.themeMode.index);
    await prefs.setBool(_testModeKey, settings.testModeEnabled);
    await prefs.setBool(_transitModeEnabledKey, settings.transitModeEnabled);
    await prefs.setInt(_transitModeWakeKey, settings.transitModeWake.index);
    await prefs.setInt(_alarmSoundModeKey, settings.alarmSoundMode.index);
  }
}
