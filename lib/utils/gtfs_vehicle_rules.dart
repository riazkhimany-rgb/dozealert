import '../models/transit_vehicle_type.dart';

class GtfsVehicleTypeRule {
  const GtfsVehicleTypeRule({
    this.routeShortNamePattern,
    this.routeLongNamePrefix,
    required this.vehicleType,
  });

  final RegExp? routeShortNamePattern;
  final String? routeLongNamePrefix;
  final TransitVehicleType vehicleType;
}

/// Agency-specific route → vehicle type rules (catalog config, not parser hacks).
abstract final class GtfsVehicleRules {
  static final Map<String, List<GtfsVehicleTypeRule>> rulesByFeedId = {
    'ttc': [
      GtfsVehicleTypeRule(
        routeShortNamePattern: RegExp(r'^[1-4]$'),
        vehicleType: TransitVehicleType.subway,
      ),
      GtfsVehicleTypeRule(
        routeLongNamePrefix: 'line 1',
        vehicleType: TransitVehicleType.subway,
      ),
      GtfsVehicleTypeRule(
        routeLongNamePrefix: 'line 2',
        vehicleType: TransitVehicleType.subway,
      ),
      GtfsVehicleTypeRule(
        routeLongNamePrefix: 'line 3',
        vehicleType: TransitVehicleType.subway,
      ),
      GtfsVehicleTypeRule(
        routeLongNamePrefix: 'line 4',
        vehicleType: TransitVehicleType.subway,
      ),
      GtfsVehicleTypeRule(
        routeShortNamePattern: RegExp(r'^5\d{2}$'),
        vehicleType: TransitVehicleType.streetcar,
      ),
    ],
  };

  static TransitVehicleType inferFromRouteNames({
    required String feedId,
    required String routeShortName,
    required String routeLongName,
    required TransitVehicleType defaultType,
  }) {
    final rules = rulesByFeedId[feedId];
    if (rules == null) {
      return defaultType;
    }

    final short = routeShortName.trim();
    final long = routeLongName.trim().toLowerCase();

    for (final rule in rules) {
      final pattern = rule.routeShortNamePattern;
      if (pattern != null && short.isNotEmpty && pattern.hasMatch(short)) {
        return rule.vehicleType;
      }
      final prefix = rule.routeLongNamePrefix;
      if (prefix != null && long.startsWith(prefix)) {
        return rule.vehicleType;
      }
    }

    if (feedId == 'ttc' && short.isNotEmpty) {
      return TransitVehicleType.bus;
    }

    return defaultType;
  }
}
