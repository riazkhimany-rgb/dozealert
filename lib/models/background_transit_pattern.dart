import 'dart:convert';

import 'transit_stop.dart';
import 'transit_vehicle_type.dart';

/// Compact route segment persisted for background stop evaluation.
class BackgroundTransitPattern {
  const BackgroundTransitPattern({
    required this.routeId,
    required this.directionLocked,
    required this.travelingForward,
    required this.destinationStopSequence,
    required this.stabilizedStopSequence,
    required this.segmentStops,
    this.lineLabel = '',
    this.vehicleType,
  });

  final String routeId;
  final bool directionLocked;
  final bool travelingForward;
  final int destinationStopSequence;
  final int stabilizedStopSequence;
  final List<TransitStop> segmentStops;
  final String lineLabel;
  final TransitVehicleType? vehicleType;

  bool get isValid =>
      routeId.isNotEmpty &&
      segmentStops.length >= 2 &&
      destinationStopSequence > 0;

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'directionLocked': directionLocked,
      'travelingForward': travelingForward,
      'destinationStopSequence': destinationStopSequence,
      'stabilizedStopSequence': stabilizedStopSequence,
      'lineLabel': lineLabel,
      if (vehicleType != null) 'vehicleType': vehicleType!.name,
      'segmentStops': segmentStops
          .map(
            (stop) => {
              'stopId': stop.stopId,
              'stopName': stop.stopName,
              'latitude': stop.latitude,
              'longitude': stop.longitude,
              'routeId': stop.routeId,
              'stopSequence': stop.stopSequence,
            },
          )
          .toList(growable: false),
    };
  }

  static BackgroundTransitPattern? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final stopsRaw = decoded['segmentStops'];
      if (stopsRaw is! List<dynamic> || stopsRaw.length < 2) {
        return null;
      }

      final stops = stopsRaw
          .whereType<Map>()
          .map(
            (entry) {
              final map = Map<String, dynamic>.from(entry);
              return TransitStop(
                stopId: map['stopId'] as String? ?? '',
                stopName: map['stopName'] as String? ?? '',
                latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
                longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
                routeId: map['routeId'] as String? ?? '',
                stopSequence: (map['stopSequence'] as num?)?.toInt() ?? 0,
              );
            },
          )
          .where((stop) => stop.stopId.isNotEmpty)
          .toList(growable: false);

      if (stops.length < 2) {
        return null;
      }

      return BackgroundTransitPattern(
        routeId: decoded['routeId'] as String? ?? '',
        directionLocked: decoded['directionLocked'] as bool? ?? false,
        travelingForward: decoded['travelingForward'] as bool? ?? true,
        destinationStopSequence:
            decoded['destinationStopSequence'] as int? ?? 0,
        stabilizedStopSequence:
            decoded['stabilizedStopSequence'] as int? ?? -1,
        lineLabel: decoded['lineLabel'] as String? ?? '',
        vehicleType: TransitVehicleTypeX.fromName(
          decoded['vehicleType'] as String?,
        ),
        segmentStops: stops,
      );
    } catch (_) {
      return null;
    }
  }

  BackgroundTransitPattern copyWith({
    int? stabilizedStopSequence,
  }) {
    return BackgroundTransitPattern(
      routeId: routeId,
      directionLocked: directionLocked,
      travelingForward: travelingForward,
      destinationStopSequence: destinationStopSequence,
      stabilizedStopSequence:
          stabilizedStopSequence ?? this.stabilizedStopSequence,
      segmentStops: segmentStops,
      lineLabel: lineLabel,
      vehicleType: vehicleType,
    );
  }
}
