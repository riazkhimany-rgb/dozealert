import 'dart:convert';

import 'transit_stop.dart';
import 'transit_vehicle_type.dart';
import 'transit_wake_plan.dart';

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
    this.wakeStopCount = 0,
    this.wakeStopSequence = -1,
    this.wakeToDestinationMeters,
    this.wakeArmedAtMs,
    this.wakeArmStableFixes = 0,
  });

  final String routeId;
  final bool directionLocked;
  final bool travelingForward;
  final int destinationStopSequence;
  final int stabilizedStopSequence;
  final List<TransitStop> segmentStops;
  final String lineLabel;
  final TransitVehicleType? vehicleType;
  final int wakeStopCount;
  final int wakeStopSequence;
  final double? wakeToDestinationMeters;
  final int? wakeArmedAtMs;
  final int wakeArmStableFixes;

  bool get isValid =>
      routeId.isNotEmpty &&
      segmentStops.length >= 2 &&
      destinationStopSequence > 0;

  TransitWakePlan? get wakePlan {
    final distance = wakeToDestinationMeters;
    if (wakeStopSequence <= 0 || distance == null || distance < 0) {
      return null;
    }
    return TransitWakePlan(
      routeId: routeId,
      patternKey: null,
      wakeStopCount: wakeStopCount,
      destinationStopSequence: destinationStopSequence,
      wakeStopSequence: wakeStopSequence,
      wakeToDestinationMeters: distance,
      segmentStops: segmentStops,
      travelingForward: travelingForward,
      vehicleType: vehicleType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'directionLocked': directionLocked,
      'travelingForward': travelingForward,
      'destinationStopSequence': destinationStopSequence,
      'stabilizedStopSequence': stabilizedStopSequence,
      'lineLabel': lineLabel,
      if (vehicleType != null) 'vehicleType': vehicleType!.name,
      'wakeStopCount': wakeStopCount,
      'wakeStopSequence': wakeStopSequence,
      if (wakeToDestinationMeters != null)
        'wakeToDestinationMeters': wakeToDestinationMeters,
      if (wakeArmedAtMs != null) 'wakeArmedAtMs': wakeArmedAtMs,
      'wakeArmStableFixes': wakeArmStableFixes,
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
          .map((entry) {
            final map = Map<String, dynamic>.from(entry);
            return TransitStop(
              stopId: map['stopId'] as String? ?? '',
              stopName: map['stopName'] as String? ?? '',
              latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
              longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
              routeId: map['routeId'] as String? ?? '',
              stopSequence: (map['stopSequence'] as num?)?.toInt() ?? 0,
            );
          })
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
        stabilizedStopSequence: decoded['stabilizedStopSequence'] as int? ?? -1,
        lineLabel: decoded['lineLabel'] as String? ?? '',
        vehicleType: TransitVehicleTypeX.fromName(
          decoded['vehicleType'] as String?,
        ),
        wakeStopCount: (decoded['wakeStopCount'] as num?)?.toInt() ?? 0,
        wakeStopSequence: (decoded['wakeStopSequence'] as num?)?.toInt() ?? -1,
        wakeToDestinationMeters: (decoded['wakeToDestinationMeters'] as num?)
            ?.toDouble(),
        wakeArmedAtMs: (decoded['wakeArmedAtMs'] as num?)?.toInt(),
        wakeArmStableFixes:
            (decoded['wakeArmStableFixes'] as num?)?.toInt() ?? 0,
        segmentStops: stops,
      );
    } catch (_) {
      return null;
    }
  }

  BackgroundTransitPattern copyWith({
    int? stabilizedStopSequence,
    int? wakeStopCount,
    int? wakeStopSequence,
    double? wakeToDestinationMeters,
    int? wakeArmedAtMs,
    bool clearWakeArmedAt = false,
    int? wakeArmStableFixes,
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
      wakeStopCount: wakeStopCount ?? this.wakeStopCount,
      wakeStopSequence: wakeStopSequence ?? this.wakeStopSequence,
      wakeToDestinationMeters:
          wakeToDestinationMeters ?? this.wakeToDestinationMeters,
      wakeArmedAtMs: clearWakeArmedAt
          ? null
          : wakeArmedAtMs ?? this.wakeArmedAtMs,
      wakeArmStableFixes: wakeArmStableFixes ?? this.wakeArmStableFixes,
    );
  }
}
