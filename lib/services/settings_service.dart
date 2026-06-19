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
  static const _alarmVolumeKey = 'alarm_volume';
  static const _approachSystemVolumeKey = 'approach_system_volume';
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
    final alarmVolume = prefs.getDouble(_alarmVolumeKey);
    final approachSystemVolume = prefs.getDouble(_approachSystemVolumeKey);

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
      alarmVolume: (alarmVolume ?? 1.0).clamp(0.0, 1.0),
      approachSystemVolume: AppSettings.clampApproachSystemVolume(
        approachSystemVolume ?? AppSettings.defaultApproachSystemVolume,
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
    await prefs.setDouble(_alarmVolumeKey, settings.alarmVolume.clamp(0.0, 1.0));
    await prefs.setDouble(
      _approachSystemVolumeKey,
      AppSettings.clampApproachSystemVolume(settings.approachSystemVolume),
    );
  }
}
