enum TransitVehicleType {
  train,
  bus,
  subway,
  streetcar,
}

extension TransitVehicleTypeX on TransitVehicleType {
  String get label {
    return switch (this) {
      TransitVehicleType.train => 'Train',
      TransitVehicleType.bus => 'Bus',
      TransitVehicleType.subway => 'Subway',
      TransitVehicleType.streetcar => 'Streetcar',
    };
  }

  static TransitVehicleType fromName(String? value) {
    return switch (value?.toLowerCase()) {
      'train' => TransitVehicleType.train,
      'bus' => TransitVehicleType.bus,
      'subway' => TransitVehicleType.subway,
      'streetcar' => TransitVehicleType.streetcar,
      _ => TransitVehicleType.bus,
    };
  }
}
