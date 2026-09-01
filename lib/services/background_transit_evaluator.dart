import 'package:geolocator/geolocator.dart';

import '../models/background_transit_pattern.dart';
import '../models/transit_stop.dart';
import '../utils/rider_motion_rules.dart';
import '../utils/transit_wake_tuning.dart';
import 'route_geometry_service.dart';
import 'transit_mode_service.dart';
import 'transit_stop_progress_tracker.dart';

class BackgroundTransitEvaluation {
  const BackgroundTransitEvaluation({
    required this.stopsRemaining,
    required this.stabilizedStopSequence,
    required this.onRoute,
    required this.directionLocked,
    required this.hasEstablishedProgress,
    this.alongRouteRemainingMeters,
    this.offRouteMeters,
    this.currentStop,
    this.destinationStop,
  });

  final int stopsRemaining;
  final int stabilizedStopSequence;
  final bool onRoute;
  final bool directionLocked;
  final bool hasEstablishedProgress;
  final double? alongRouteRemainingMeters;
  final double? offRouteMeters;
  final TransitStop? currentStop;
  final TransitStop? destinationStop;
}

/// Lightweight stop-based evaluation for the background location isolate.
class BackgroundTransitEvaluator {
  BackgroundTransitEvaluator({
    RouteGeometryService? routeGeometry,
    TransitStopProgressTracker? progressTracker,
  })  : _routeGeometry = routeGeometry ?? RouteGeometryService(),
        _progressTracker = progressTracker ?? TransitStopProgressTracker();

  final RouteGeometryService _routeGeometry;
  final TransitStopProgressTracker _progressTracker;
  String? _seededRouteId;
  int? _seededDestinationSequence;
  int? _seededStopSequence;

  BackgroundTransitEvaluation? evaluate({
    required BackgroundTransitPattern pattern,
    required double latitude,
    required double longitude,
    double? headingDegrees,
    double? speedMps,
    double accuracyMeters = 0,
    bool useActivityRecognition = false,
    bool? activityInVehicle,
    bool? activityOnFoot,
  }) {
    if (!pattern.isValid) {
      return null;
    }

    final destinationStop = _stopForSequence(
      pattern.segmentStops,
      pattern.destinationStopSequence,
    );
    if (destinationStop == null) {
      return null;
    }

    _seedProgressIfNeeded(pattern: pattern, destinationStop: destinationStop);

    final polyline = _routeGeometry.buildPolyline(
      routeStops: pattern.segmentStops,
      destinationStop: destinationStop,
    );
    final projection = _routeGeometry.projectOnPolyline(
      polyline: polyline,
      latitude: latitude,
      longitude: longitude,
    );
    if (projection == null) {
      return null;
    }

    var currentStop = _routeGeometry.matchCurrentStop(
      polyline: polyline,
      projection: projection,
      destinationStop: destinationStop,
      maxOffRouteMeters: TransitModeService.routeStopMatchMeters,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
      stopSnapAlongToleranceMeters:
          TransitWakeTuning.stopSnapAlongToleranceMeters(pattern.vehicleType),
    );

    currentStop ??= _routeGeometry.bestStopAtOrBehindProjection(
      polyline: polyline,
      projection: projection,
    );

    if (currentStop == null) {
      return const BackgroundTransitEvaluation(
        stopsRemaining: -1,
        stabilizedStopSequence: -1,
        onRoute: false,
        directionLocked: false,
        hasEstablishedProgress: false,
      );
    }

    final highConfidence = RiderMotionRules.allowsRelaxedStopProgress(
      useActivityRecognition: useActivityRecognition,
      activityInVehicle: activityInVehicle,
      activityOnFoot: activityOnFoot,
      directionLocked: pattern.directionLocked,
      offRouteMeters: projection.offRouteMeters,
      accuracyMeters: accuracyMeters,
      speedMps: speedMps,
    );

    var alongRouteRemainingMeters = _routeGeometry.alongRouteRemainingMeters(
      polyline: polyline,
      projection: projection,
      destinationStop: destinationStop,
    );

    final stabilizedStop = _progressTracker.reconcile(
      routeId: pattern.routeId,
      destinationStop: destinationStop,
      rawStop: currentStop,
      routeStops: pattern.segmentStops,
      maxStepsPerFix: TransitWakeTuning.maxStepsPerFix(
        vehicleType: pattern.vehicleType,
        highConfidence: highConfidence,
      ),
      latitude: latitude,
      longitude: longitude,
      maxAdvanceDistanceMeters: TransitWakeTuning.maxStopAdvanceHaversineMeters(
        pattern.vehicleType,
      ),
      alongRouteRemainingMeters: alongRouteRemainingMeters,
      vehicleType: pattern.vehicleType,
      accuracyMeters: accuracyMeters,
    );

    final stopsRemaining = _stopsBetween(
      currentStop: stabilizedStop,
      destinationStop: destinationStop,
      routeStops: pattern.segmentStops,
    );

    if (alongRouteRemainingMeters != null && stopsRemaining <= 1) {
      final haversine = Geolocator.distanceBetween(
        latitude,
        longitude,
        destinationStop.latitude,
        destinationStop.longitude,
      );
      if (haversine < alongRouteRemainingMeters!) {
        alongRouteRemainingMeters = haversine;
      }
    }

    return BackgroundTransitEvaluation(
      stopsRemaining: stopsRemaining,
      stabilizedStopSequence: stabilizedStop.stopSequence,
      onRoute: true,
      directionLocked: pattern.directionLocked,
      hasEstablishedProgress: _progressTracker.hasEstablishedProgress,
      alongRouteRemainingMeters: alongRouteRemainingMeters,
      offRouteMeters: projection.offRouteMeters,
      currentStop: stabilizedStop,
      destinationStop: destinationStop,
    );
  }

  void resetProgress() {
    _progressTracker.reset();
    _seededRouteId = null;
    _seededDestinationSequence = null;
    _seededStopSequence = null;
  }

  void _seedProgressIfNeeded({
    required BackgroundTransitPattern pattern,
    required TransitStop destinationStop,
  }) {
    final sequence = pattern.stabilizedStopSequence;
    if (sequence <= 0) {
      return;
    }

    if (_seededRouteId == pattern.routeId &&
        _seededDestinationSequence == pattern.destinationStopSequence &&
        _seededStopSequence == sequence) {
      return;
    }

    _progressTracker.seedAcceptedSequence(
      routeId: pattern.routeId,
      destinationStopSequence: pattern.destinationStopSequence,
      acceptedStopSequence: sequence,
      travelingForward: pattern.travelingForward,
    );
    _seededRouteId = pattern.routeId;
    _seededDestinationSequence = pattern.destinationStopSequence;
    _seededStopSequence = sequence;
  }

  int _stopsBetween({
    required TransitStop currentStop,
    required TransitStop destinationStop,
    required List<TransitStop> routeStops,
  }) {
    final currentIndex = routeStops.indexWhere(
      (stop) => stop.stopSequence == currentStop.stopSequence,
    );
    final destinationIndex = routeStops.indexWhere(
      (stop) => stop.stopSequence == destinationStop.stopSequence,
    );
    if (currentIndex < 0 || destinationIndex < 0) {
      return -1;
    }

    return (destinationIndex - currentIndex).abs();
  }

  TransitStop? _stopForSequence(List<TransitStop> stops, int sequence) {
    for (final stop in stops) {
      if (stop.stopSequence == sequence) {
        return stop;
      }
    }
    return null;
  }
}
