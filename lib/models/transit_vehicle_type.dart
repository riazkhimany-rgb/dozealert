enum TransitVehicleType {
  train,
  bus,
  subway,
  streetcar,
  lightRail,
}

extension TransitVehicleTypeX on TransitVehicleType {
  String get label {
    return switch (this) {
      TransitVehicleType.train => 'Train',
      TransitVehicleType.bus => 'Bus',
      TransitVehicleType.subway => 'Subway',
      TransitVehicleType.streetcar => 'Streetcar',
      TransitVehicleType.lightRail => 'Light rail',
    };
  }

  static TransitVehicleType fromName(String? value) {
    return switch (value?.toLowerCase().replaceAll(' ', '_')) {
      'train' => TransitVehicleType.train,
      'bus' => TransitVehicleType.bus,
      'subway' => TransitVehicleType.subway,
      'streetcar' => TransitVehicleType.streetcar,
      'light_rail' || 'lightrail' => TransitVehicleType.lightRail,
      _ => TransitVehicleType.bus,
    };
  }

  static List<TransitVehicleType> listFromJson(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => fromName(entry?.toString()))
          .toList(growable: false);
    }
    if (value is String && value.isNotEmpty) {
      return [fromName(value)];
    }
    return const [TransitVehicleType.bus];
  }
}
