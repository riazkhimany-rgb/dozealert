import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._settingsService);

  final SettingsService _settingsService;

  ThemeMode get themeMode => _settingsService.settings.themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == themeMode) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(themeMode: mode),
    );
    notifyListeners();
  }
}
