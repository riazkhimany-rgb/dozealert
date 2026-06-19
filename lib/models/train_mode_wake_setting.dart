enum TrainModeWakeSetting {
  atDestination,
  oneStationBefore,
  twoStationsBefore,
}

extension TrainModeWakeSettingX on TrainModeWakeSetting {
  int get wakeStationCount {
    return switch (this) {
      TrainModeWakeSetting.atDestination => 0,
      TrainModeWakeSetting.oneStationBefore => 1,
      TrainModeWakeSetting.twoStationsBefore => 2,
    };
  }

  String get label {
    return switch (this) {
      TrainModeWakeSetting.atDestination => 'At destination',
      TrainModeWakeSetting.oneStationBefore => '1 station before',
      TrainModeWakeSetting.twoStationsBefore => '2 stations before',
    };
  }

  static TrainModeWakeSetting fromIndex(int index) {
    if (index < 0 || index >= TrainModeWakeSetting.values.length) {
      return TrainModeWakeSetting.oneStationBefore;
    }
    return TrainModeWakeSetting.values[index];
  }
}
