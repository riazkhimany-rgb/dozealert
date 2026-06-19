import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/train_mode_wake_setting.dart';

class SettingsService {
  static const _themeModeKey = 'theme_mode';
  static const _testModeKey = 'test_mode_enabled';
  static const _trainModeEnabledKey = 'train_mode_enabled';
  static const _trainModeWakeKey = 'train_mode_wake';

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey);
    final testModeEnabled = prefs.getBool(_testModeKey) ?? false;
    final trainModeEnabled = prefs.getBool(_trainModeEnabledKey) ?? false;
    final trainModeWakeIndex = prefs.getInt(_trainModeWakeKey);

    _settings = AppSettings(
      themeMode: themeIndex != null && themeIndex < ThemeMode.values.length
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system,
      testModeEnabled: testModeEnabled,
      trainModeEnabled: trainModeEnabled,
      trainModeWake: TrainModeWakeSettingX.fromIndex(
        trainModeWakeIndex ?? TrainModeWakeSetting.oneStationBefore.index,
      ),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, settings.themeMode.index);
    await prefs.setBool(_testModeKey, settings.testModeEnabled);
    await prefs.setBool(_trainModeEnabledKey, settings.trainModeEnabled);
    await prefs.setInt(_trainModeWakeKey, settings.trainModeWake.index);
  }
}
