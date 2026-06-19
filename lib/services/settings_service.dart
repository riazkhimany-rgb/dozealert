import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  static const _themeModeKey = 'theme_mode';
  static const _testModeKey = 'test_mode_enabled';

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey);
    final testModeEnabled = prefs.getBool(_testModeKey) ?? false;

    _settings = AppSettings(
      themeMode: themeIndex != null && themeIndex < ThemeMode.values.length
          ? ThemeMode.values[themeIndex]
          : ThemeMode.system,
      testModeEnabled: testModeEnabled,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, settings.themeMode.index);
    await prefs.setBool(_testModeKey, settings.testModeEnabled);
  }
}
