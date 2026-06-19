enum AlarmSoundMode {
  followDevice,
  alwaysPlaySound,
}

extension AlarmSoundModeX on AlarmSoundMode {
  String get label {
    return switch (this) {
      AlarmSoundMode.followDevice => 'Follow phone settings',
      AlarmSoundMode.alwaysPlaySound => 'Always play sound',
    };
  }

  String get description {
    return switch (this) {
      AlarmSoundMode.followDevice =>
        'Uses media volume and may stay silent when your phone is on vibrate.',
      AlarmSoundMode.alwaysPlaySound =>
        'Plays the alarm sound even when your phone is on vibrate or silent.',
    };
  }

  static AlarmSoundMode fromIndex(int index) {
    if (index < 0 || index >= AlarmSoundMode.values.length) {
      return AlarmSoundMode.followDevice;
    }
    return AlarmSoundMode.values[index];
  }
}
