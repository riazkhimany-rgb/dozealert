import 'package:flutter/material.dart';

import '../models/alarm_sound_mode.dart';
import '../models/transit_mode_wake_setting.dart';

class AppSettings {
  static const defaultApproachSystemVolume = 0.50;
  static const minApproachSystemVolume = 0.10;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.testModeEnabled = false,
    this.transitModeEnabled = false,
    this.transitModeWake = TransitModeWakeSetting.oneStopBefore,
    this.alarmSoundMode = AlarmSoundMode.followDevice,
    this.alarmVolume = 1.0,
    this.approachSystemVolume = defaultApproachSystemVolume,
  });

  final ThemeMode themeMode;
  final bool testModeEnabled;
  final bool transitModeEnabled;
  final TransitModeWakeSetting transitModeWake;
  final AlarmSoundMode alarmSoundMode;
  final double alarmVolume;
  final double approachSystemVolume;

  bool get alwaysPlayAlarmSound =>
      alarmSoundMode == AlarmSoundMode.alwaysPlaySound;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? testModeEnabled,
    bool? transitModeEnabled,
    TransitModeWakeSetting? transitModeWake,
    AlarmSoundMode? alarmSoundMode,
    double? alarmVolume,
    double? approachSystemVolume,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      testModeEnabled: testModeEnabled ?? this.testModeEnabled,
      transitModeEnabled: transitModeEnabled ?? this.transitModeEnabled,
      transitModeWake: transitModeWake ?? this.transitModeWake,
      alarmSoundMode: alarmSoundMode ?? this.alarmSoundMode,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      approachSystemVolume: approachSystemVolume ?? this.approachSystemVolume,
    );
  }

  static double clampApproachSystemVolume(double volume) {
    return volume.clamp(minApproachSystemVolume, 1.0);
  }
}
