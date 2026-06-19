import 'package:flutter/material.dart';

import '../models/alarm_sound_mode.dart';
import '../models/transit_mode_wake_setting.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.testModeEnabled = false,
    this.transitModeEnabled = false,
    this.transitModeWake = TransitModeWakeSetting.oneStopBefore,
    this.alarmSoundMode = AlarmSoundMode.followDevice,
  });

  final ThemeMode themeMode;
  final bool testModeEnabled;
  final bool transitModeEnabled;
  final TransitModeWakeSetting transitModeWake;
  final AlarmSoundMode alarmSoundMode;

  bool get alwaysPlayAlarmSound =>
      alarmSoundMode == AlarmSoundMode.alwaysPlaySound;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? testModeEnabled,
    bool? transitModeEnabled,
    TransitModeWakeSetting? transitModeWake,
    AlarmSoundMode? alarmSoundMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      testModeEnabled: testModeEnabled ?? this.testModeEnabled,
      transitModeEnabled: transitModeEnabled ?? this.transitModeEnabled,
      transitModeWake: transitModeWake ?? this.transitModeWake,
      alarmSoundMode: alarmSoundMode ?? this.alarmSoundMode,
    );
  }
}
