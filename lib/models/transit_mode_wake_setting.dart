enum TransitModeWakeSetting {
  atDestination,
  oneStopBefore,
  twoStopsBefore,
}

extension TransitModeWakeSettingX on TransitModeWakeSetting {
  int get wakeStopCount {
    return switch (this) {
      TransitModeWakeSetting.atDestination => 0,
      TransitModeWakeSetting.oneStopBefore => 1,
      TransitModeWakeSetting.twoStopsBefore => 2,
    };
  }

  String get label {
    return switch (this) {
      TransitModeWakeSetting.atDestination => 'At destination',
      TransitModeWakeSetting.oneStopBefore => '1 stop before',
      TransitModeWakeSetting.twoStopsBefore => '2 stops before',
    };
  }

  static TransitModeWakeSetting fromIndex(int index) {
    if (index < 0 || index >= TransitModeWakeSetting.values.length) {
      return TransitModeWakeSetting.oneStopBefore;
    }
    return TransitModeWakeSetting.values[index];
  }

  /// Migrates legacy train-mode wake indices (same ordering).
  static TransitModeWakeSetting fromLegacyIndex(int index) {
    return fromIndex(index);
  }
}
