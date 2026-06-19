import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.testModeEnabled = false,
  });

  final ThemeMode themeMode;
  final bool testModeEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? testModeEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      testModeEnabled: testModeEnabled ?? this.testModeEnabled,
    );
  }
}
