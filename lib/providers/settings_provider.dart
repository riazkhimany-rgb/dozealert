import 'package:flutter/material.dart';

import '../models/train_mode_wake_setting.dart';
import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settingsService);

  final SettingsService _settingsService;

  bool get testModeEnabled => _settingsService.settings.testModeEnabled;
  bool get trainModeEnabled => _settingsService.settings.trainModeEnabled;
  TrainModeWakeSetting get trainModeWake =>
      _settingsService.settings.trainModeWake;

  Future<void> setTestModeEnabled(bool enabled) async {
    if (enabled == testModeEnabled) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(testModeEnabled: enabled),
    );
    notifyListeners();
  }

  Future<void> setTrainModeEnabled(bool enabled) async {
    if (enabled == trainModeEnabled) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(trainModeEnabled: enabled),
    );
    notifyListeners();
  }

  Future<void> setTrainModeWake(TrainModeWakeSetting wakeSetting) async {
    if (wakeSetting == trainModeWake) {
      return;
    }

    await _settingsService.saveSettings(
      _settingsService.settings.copyWith(trainModeWake: wakeSetting),
    );
    notifyListeners();
  }
}
