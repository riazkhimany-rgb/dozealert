import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  AppSettings copyWith({ThemeMode? themeMode}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode);
  }
}
