import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settingsService);

  final SettingsService _settingsService;

  bool get testModeEnabled => _settingsService.settings.testModeEnabled;

  Future<void> setTestModeEnabled(bool enabled) async {
    if (enabled == testModeEnabled) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(testModeEnabled: enabled),
    );
    notifyListeners();
  }
}
