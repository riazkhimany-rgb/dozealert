import 'package:flutter/material.dart';

import 'train_mode_wake_setting.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.testModeEnabled = false,
    this.trainModeEnabled = false,
    this.trainModeWake = TrainModeWakeSetting.oneStationBefore,
  });

  final ThemeMode themeMode;
  final bool testModeEnabled;
  final bool trainModeEnabled;
  final TrainModeWakeSetting trainModeWake;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? testModeEnabled,
    bool? trainModeEnabled,
    TrainModeWakeSetting? trainModeWake,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      testModeEnabled: testModeEnabled ?? this.testModeEnabled,
      trainModeEnabled: trainModeEnabled ?? this.trainModeEnabled,
      trainModeWake: trainModeWake ?? this.trainModeWake,
    );
  }
}
