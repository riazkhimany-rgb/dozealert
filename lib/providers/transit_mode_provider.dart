import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/background_transit_pattern.dart';
import '../models/monitoring_state.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_stop.dart';
import '../models/transit_vehicle_type.dart';
import '../models/transit_wake_plan.dart';
import '../utils/transit_wake_tuning.dart';
import '../models/trip_pattern_concern.dart';
import '../services/activity_recognition_service.dart';
import '../services/monitoring_storage_service.dart';
import '../services/settings_service.dart';
import '../services/transit_mode_service.dart';
import '../services/transit_stop_progress_tracker.dart';
import '../utils/transit_wake_message.dart';
import '../utils/transit_wake_trigger.dart';
import 'monitoring_provider.dart';

class TransitModeProvider extends ChangeNotifier {
  TransitModeProvider(
    this._transitModeService,
    this._settingsService,
    this._monitoringProvider,
    this._monitoringStorage,
    ActivityRecognitionService activityRecognitionService,
  ) {
    _monitoringProvider.addListener(_handleMonitoringChanged);
  }

  final TransitModeService _transitModeService;
  final SettingsService _settingsService;
  final MonitoringProvider _monitoringProvider;
  final MonitoringStorageService _monitoringStorage;
  final TransitStopProgressTracker _stopProgressTracker =
      TransitStopProgressTracker();
  final _MovingAwayDetector _movingAwayDetector = _MovingAwayDetector();

  double _lastAccuracyMeters = 0;

  TransitModeSnapshot _snapshot = TransitModeSnapshot.inactive;
  TransitModeSnapshot? _lastActiveSnapshot;
  String? _activeRouteId;
  bool _approachAlarmTriggered = false;
  TransitWakePlan? _wakePlan;
  DateTime? _wakeArmedAt;
  int _wakeArmStableFixes = 0;
  TransitWakeDecisionReason? _lastWakeDecisionReason;

  TransitModeSnapshot get snapshot => _snapshot;

  /// Snapshot for UI: keeps last known stop progress during brief GPS loss.
  TransitModeSnapshot get displaySnapshot {
    if (_snapshot.isActive) {
      return _snapshot;
    }
    if (_lastActiveSnapshot != null &&
        _monitoringProvider.currentState == MonitoringState.monitoring) {
      return _lastActiveSnapshot!.copyWith(gpsStale: true);
    }
    return _snapshot;
  }

  bool get isActive => _snapshot.isActive;
  bool get gpsSignalLost => displaySnapshot.gpsStale;
  bool get isEnabled => _settingsService.settings.transitModeEnabled;

  /// Route stops from the user's current stop through the destination, inclusive.
  List<TransitStop> get routeSegmentStops =>
      _routeSegmentStopsFor(displaySnapshot);

  TransitWakeDecisionReason? get lastWakeDecisionReason =>
      _lastWakeDecisionReason;

  List<TransitStop> _routeSegmentStopsFor(TransitModeSnapshot source) {
    final route = source.route;
    final current = source.currentStop;
    final destination = source.destinationStop;
    if (!source.isActive ||
        route == null ||
        current == null ||
        destination == null) {
      return const [];
    }

    return _transitModeService.getStopsFromCurrentToDestination(
      currentStop: current,
      destinationStop: destination,
      routeId: route.routeId,
      lockedPatternKey: _transitModeService.tripSession.lockedPatternKey,
    );
  }

  bool get shouldUseDistanceFallback =>
      _settingsService.settings.transitModeEnabled &&
      !_snapshot.isActive &&
      !isTransitTrackableDestination;

  bool get isTransitTrackableDestination {
    final destination = _monitoringProvider.selectedDestination;
    if (destination == null) {
      return false;
    }

    return _transitModeService.isTransitTrackableDestination(
      destination,
      routeId: _activeRouteId,
    );
  }

  /// True when the rider has passed their destination on the locked pattern.
  bool get shouldFlagTransitMissedStop {
    if (!_settingsService.settings.transitModeEnabled || !_snapshot.isActive) {
      return false;
    }
    if (_approachAlarmTriggered) {
      return false;
    }
    if (!_transitModeService.tripSession.isDirectionLocked) {
      return false;
    }
    if (!_stopProgressTracker.hasEstablishedProgress) {
      return false;
    }
    if (_snapshot.hasTripConcern) {
      return false;
    }

    final current = _snapshot.currentStop;
    final destination = _snapshot.destinationStop;
    if (current == null || destination == null) {
      return false;
    }

    final segment = routeSegmentStops;
    if (segment.length < 2) {
      return false;
    }

    final travelingForward =
        destination.stopSequence >= segment.first.stopSequence;
    if (travelingForward) {
      return current.stopSequence > destination.stopSequence;
    }
    return current.stopSequence < destination.stopSequence;
  }

  bool get shouldTriggerApproachAlarm {
    if (!_settingsService.settings.transitModeEnabled || !_snapshot.isActive) {
      return false;
    }

    if (_approachAlarmTriggered) {
      return false;
    }

    final plan = _wakePlan;
    if (plan == null) {
      return false;
    }

    final now = DateTime.now();
    final decision = TransitWakeTrigger.evaluatePlan(
      plan: plan,
      directionLocked: _snapshot.directionLocked,
      hasEstablishedProgress: _stopProgressTracker.hasEstablishedProgress,
      hasTripConcern: _snapshot.hasTripConcern,
      currentStop: _snapshot.currentStop,
      alongRouteRemainingMeters: _snapshot.alongRouteRemainingMeters,
      offRouteMeters: _snapshot.offRouteMeters,
      accuracyMeters: _lastAccuracyMeters,
      gpsStale: _snapshot.gpsStale,
      armedAt: _wakeArmedAt,
      armStableFixes: _wakeArmStableFixes,
      now: now,
    );
    _lastWakeDecisionReason = decision.reason;

    if (decision.isArmed) {
      _wakeArmedAt ??= now;
      _wakeArmStableFixes++;
    } else {
      _wakeArmedAt = null;
      _wakeArmStableFixes = 0;
    }

    return decision.shouldTrigger;
  }

  /// Copy for the current approach alarm, based on wake-by-stops setting.
  WakeAlertCopy get approachAlarmCopy => approachAlarmCopyWith();

  WakeAlertCopy approachAlarmCopyWith({int? stopsRemainingOverride}) {
    // Prefer the locked plan's wake count so alarm copy cannot drift from the
    // stop that will actually trigger (e.g. after a mid-trip settings change).
    final planWakeCount = _wakePlan?.wakeStopCount;
    final wakeSetting = planWakeCount == null
        ? _settingsService.settings.transitModeWake
        : switch (planWakeCount) {
            0 => TransitModeWakeSetting.atDestination,
            2 => TransitModeWakeSetting.twoStopsBefore,
            _ => TransitModeWakeSetting.oneStopBefore,
          };
    return TransitWakeMessage.forTransitAlarm(
      snapshot: _snapshot,
      wakeSetting: wakeSetting,
      segmentStops: _wakePlan?.segmentStops ?? routeSegmentStops,
      fallbackDestinationName: _monitoringProvider.selectedDestination?.name,
      stopsRemainingOverride: stopsRemainingOverride,
    );
  }

  void updateFromLocation({
    required double? latitude,
    required double? longitude,
    double? headingDegrees,
    double? speedMps,
    double? accuracyMeters,
    bool directionInferenceOnly = false,
    DateTime? fixTimestamp,
  }) {
    if (!_settingsService.settings.transitModeEnabled) {
      if (_snapshot.isActive || _lastActiveSnapshot != null) {
        _snapshot = TransitModeSnapshot.inactive;
        _lastActiveSnapshot = null;
        _stopProgressTracker.reset();
        _movingAwayDetector.reset();
        _resetWakePlan();
        _transitModeService.resetTripSession();
        notifyListeners();
      }
      return;
    }

    if (accuracyMeters != null && accuracyMeters > 0) {
      _lastAccuracyMeters = accuracyMeters;
    }
    final rawSnapshot = _transitModeService.evaluate(
      destination: _monitoringProvider.selectedDestination,
      latitude: latitude,
      longitude: longitude,
      routeId: _activeRouteId,
      maxStopProximityMeters: TransitModeService.routeStopMatchMeters,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
      accuracyMeters: accuracyMeters,
      fixTimestamp: fixTimestamp,
    );
    if (directionInferenceOnly) {
      if (rawSnapshot.route?.routeId != null) {
        _activeRouteId = rawSnapshot.route!.routeId;
      }
      if (rawSnapshot.isActive || rawSnapshot.directionConfirming) {
        final nextSnapshot = rawSnapshot.isActive
            ? _stabilizeSnapshot(rawSnapshot)
            : rawSnapshot;
        if (nextSnapshot.isActive) {
          _ensureWakePlan(nextSnapshot);
          _lastActiveSnapshot = nextSnapshot;
          unawaited(_monitoringStorage.setTransitOnRouteActive(true));
          unawaited(_persistTransitBackgroundSnapshot(nextSnapshot));
        }
        _snapshot = nextSnapshot;
        notifyListeners();
      }
      return;
    }

    final nextSnapshot = _flagMovingAway(
      _stabilizeSnapshot(rawSnapshot),
      latitude: latitude,
      longitude: longitude,
    );
    _ensureWakePlan(nextSnapshot);

    if (nextSnapshot.route?.routeId != null) {
      _activeRouteId = nextSnapshot.route!.routeId;
    }

    if (nextSnapshot.isActive) {
      _lastActiveSnapshot = nextSnapshot;
      if (nextSnapshot != _snapshot) {
        _snapshot = nextSnapshot;
        unawaited(_monitoringStorage.setTransitOnRouteActive(true));
        unawaited(_persistTransitBackgroundSnapshot(nextSnapshot));
        notifyListeners();
      }
      return;
    }

    if (_lastActiveSnapshot != null &&
        _monitoringProvider.currentState == MonitoringState.monitoring) {
      if (_snapshot.isActive) {
        _snapshot = TransitModeSnapshot.inactive;
        unawaited(_monitoringStorage.setTransitOnRouteActive(false));
      }
      notifyListeners();
      return;
    }

    if (nextSnapshot != _snapshot || _lastActiveSnapshot != null) {
      _snapshot = nextSnapshot;
      _lastActiveSnapshot = null;
      unawaited(_monitoringStorage.setTransitOnRouteActive(false));
      unawaited(_monitoringStorage.clearTransitBackgroundSnapshot());
      notifyListeners();
    }
  }

  void _ensureWakePlan(TransitModeSnapshot snapshot) {
    final wakeStopCount =
        _settingsService.settings.transitModeWake.wakeStopCount;
    final existing = _wakePlan;

    // Settings can change while GPS briefly reports inactive. Still rebuild the
    // locked plan so "At destination" actually moves the wake stop.
    if (!snapshot.isActive ||
        !snapshot.directionLocked ||
        snapshot.route == null ||
        snapshot.destinationStop == null) {
      if (existing != null &&
          existing.isValid &&
          existing.wakeStopCount != wakeStopCount) {
        _rebuildWakePlan(
          existing: existing,
          wakeStopCount: wakeStopCount,
          routeId: existing.routeId,
          destination: existing.destinationStop!,
          patternKey: existing.patternKey,
          vehicleType: existing.vehicleType,
        );
      }
      return;
    }

    final route = snapshot.route!;
    final destination = snapshot.destinationStop!;
    final patternKey = _transitModeService.tripSession.lockedPatternKey;
    final sameTrip =
        existing?.matchesTrip(
          routeId: route.routeId,
          destinationStopSequence: destination.stopSequence,
          patternKey: patternKey,
        ) ??
        false;
    if (sameTrip && existing!.wakeStopCount == wakeStopCount) {
      return;
    }

    final fixedSegment = sameTrip
        ? existing!.segmentStops
        : List<TransitStop>.unmodifiable(_routeSegmentStopsFor(snapshot));
    if (fixedSegment.isEmpty) {
      return;
    }

    _rebuildWakePlan(
      existing: sameTrip ? existing : null,
      wakeStopCount: wakeStopCount,
      routeId: route.routeId,
      destination: destination,
      patternKey: patternKey,
      vehicleType: snapshot.vehicleType ?? route.vehicleType,
      segmentStops: fixedSegment,
    );
  }

  void _rebuildWakePlan({
    required int wakeStopCount,
    required String routeId,
    required TransitStop destination,
    required String? patternKey,
    TransitVehicleType? vehicleType,
    TransitWakePlan? existing,
    List<TransitStop>? segmentStops,
  }) {
    final fixedSegment =
        segmentStops ?? existing?.segmentStops ?? const <TransitStop>[];
    final wakeStop = TransitWakePlan.selectWakeStop(
      segmentStops: fixedSegment,
      wakeStopCount: wakeStopCount,
    );
    if (fixedSegment.isEmpty || wakeStop == null) {
      return;
    }

    final wakeToDestinationMeters = _transitModeService
        .distanceBetweenStopsAlongRoute(
          routeId: routeId,
          segmentStops: fixedSegment,
          fromStop: wakeStop,
          destinationStop: destination,
          lockedPatternKey: patternKey,
        );
    if (wakeToDestinationMeters == null) {
      return;
    }

    final travelingForward =
        destination.stopSequence >= fixedSegment.first.stopSequence;
    final nextPlan = TransitWakePlan(
      routeId: routeId,
      patternKey: patternKey,
      wakeStopCount: wakeStopCount,
      destinationStopSequence: destination.stopSequence,
      wakeStopSequence: wakeStop.stopSequence,
      wakeToDestinationMeters: wakeToDestinationMeters,
      segmentStops: fixedSegment,
      travelingForward: travelingForward,
      vehicleType: vehicleType,
    );
    if (_wakePlan?.wakeStopSequence != nextPlan.wakeStopSequence) {
      _wakeArmedAt = null;
      _wakeArmStableFixes = 0;
      _lastWakeDecisionReason = null;
    }
    _wakePlan = nextPlan;
  }

  void _resetWakePlan() {
    _wakePlan = null;
    _wakeArmedAt = null;
    _wakeArmStableFixes = 0;
    _lastWakeDecisionReason = null;
  }

  Future<void> _persistTransitBackgroundSnapshot(
    TransitModeSnapshot snapshot,
  ) async {
    if (!_settingsService.settings.transitModeEnabled || !snapshot.isActive) {
      await _monitoringStorage.clearTransitBackgroundSnapshot();
      return;
    }

    final copy = TransitWakeMessage.forTransitAlarm(
      snapshot: snapshot,
      wakeSetting: _settingsService.settings.transitModeWake,
      segmentStops: _wakePlan?.segmentStops ?? _routeSegmentStopsFor(snapshot),
      fallbackDestinationName: _monitoringProvider.selectedDestination?.name,
    );

    await _monitoringStorage.saveTransitBackgroundSnapshot(
      transitActive: true,
      stopsRemaining: snapshot.stopsRemaining,
      wakeStopCount: _settingsService.settings.transitModeWake.wakeStopCount,
      directionLocked: _transitModeService.tripSession.isDirectionLocked,
      hasTripConcern: snapshot.hasTripConcern,
      tripConcernType: snapshot.tripConcern ?? '',
      alarmHeadline: copy.headline,
      alarmBody: copy.detailMessage,
      alarmTts: copy.ttsPhrase,
      alarmStopName: copy.primaryStopName,
      alarmSubline: copy.wearSubline ?? copy.secondaryLine ?? '',
    );

    final plan = _wakePlan;
    final segmentStops = plan?.segmentStops ?? _routeSegmentStopsFor(snapshot);
    final destination = snapshot.destinationStop;
    final route = snapshot.route;
    final current = snapshot.currentStop;
    if (plan != null && plan.isValid && destination != null && route != null) {
      final travelingForward =
          destination.stopSequence >= segmentStops.first.stopSequence;
      await _monitoringStorage.saveBackgroundTransitPattern(
        BackgroundTransitPattern(
          routeId: route.routeId,
          directionLocked: _transitModeService.tripSession.isDirectionLocked,
          travelingForward: travelingForward,
          destinationStopSequence: destination.stopSequence,
          stabilizedStopSequence: current?.stopSequence ?? -1,
          segmentStops: segmentStops,
          lineLabel: route.lineName,
          vehicleType: snapshot.vehicleType ?? route.vehicleType,
          wakeStopCount: plan.wakeStopCount,
          wakeStopSequence: plan.wakeStopSequence,
          wakeToDestinationMeters: plan.wakeToDestinationMeters,
          wakeArmedAtMs: _wakeArmedAt?.millisecondsSinceEpoch,
          wakeArmStableFixes: _wakeArmStableFixes,
        ),
      );
    }
  }

  void setActiveRouteId(String? routeId) {
    _activeRouteId = routeId;
  }

  void markApproachAlarmTriggered() {
    _approachAlarmTriggered = true;
  }

  void resetApproachAlarm() {
    _approachAlarmTriggered = false;
  }

  void refreshFromSettings() {
    if (!_settingsService.settings.transitModeEnabled) {
      if (_snapshot.isActive ||
          _approachAlarmTriggered ||
          _lastActiveSnapshot != null) {
        _snapshot = TransitModeSnapshot.inactive;
        _lastActiveSnapshot = null;
        _approachAlarmTriggered = false;
        _stopProgressTracker.reset();
        _movingAwayDetector.reset();
        _resetWakePlan();
        _transitModeService.resetTripSession();
        notifyListeners();
      }
      return;
    }

    if (_monitoringProvider.selectedDestination != null) {
      _approachAlarmTriggered = false;
      // Prefer the last active snapshot when GPS is briefly stale so a wake
      // setting change (e.g. Destination) still updates the locked plan.
      final planSource = _snapshot.isActive
          ? _snapshot
          : (_lastActiveSnapshot ?? _snapshot);
      _ensureWakePlan(planSource);
      if (_snapshot.isActive || _lastActiveSnapshot != null) {
        unawaited(
          _persistTransitBackgroundSnapshot(
            _snapshot.isActive ? _snapshot : _lastActiveSnapshot!,
          ),
        );
      }
      notifyListeners();
    }
  }

  void simulateOneStopRemaining() {
    if (!_snapshot.isActive) {
      return;
    }

    _snapshot = TransitModeSnapshot(
      isActive: true,
      agency: _snapshot.agency,
      route: _snapshot.route,
      vehicleType: _snapshot.vehicleType,
      destinationStop: _snapshot.destinationStop,
      currentStop: _snapshot.previousStop ?? _snapshot.currentStop,
      previousStop: _snapshot.previousStop,
      nextStop: _snapshot.destinationStop,
      stopsRemaining: 1,
      status: 'Simulated (1 remaining)',
    );
    _lastActiveSnapshot = _snapshot;
    _approachAlarmTriggered = false;
    notifyListeners();
  }

  void _handleMonitoringChanged() {
    if (_monitoringProvider.selectedDestination == null) {
      _snapshot = TransitModeSnapshot.inactive;
      _lastActiveSnapshot = null;
      _approachAlarmTriggered = false;
      _stopProgressTracker.reset();
      _movingAwayDetector.reset();
      _resetWakePlan();
      _transitModeService.resetTripSession();
      unawaited(_monitoringStorage.clearTransitBackgroundSnapshot());
      notifyListeners();
      return;
    }

    _approachAlarmTriggered = false;
    _stopProgressTracker.reset();
    _movingAwayDetector.reset();
    _resetWakePlan();
    _transitModeService.resetTripSession();

    final destination = _monitoringProvider.selectedDestination;
    if (_activeRouteId != null && destination != null) {
      _transitModeService.seedDirectionFromDestination(
        destination: destination,
        routeId: _activeRouteId!,
      );
    }

    updateFromLocation(latitude: null, longitude: null);
  }

  /// Surfaces a wrong-direction concern when the rider is clearly moving away
  /// from the destination stop, based on a sustained increase in straight-line
  /// distance. This is independent of the pattern-lock heuristics, so it still
  /// catches the case where someone starts monitoring after already passing
  /// their stop (and the pattern inference orients the destination "ahead").
  TransitModeSnapshot _flagMovingAway(
    TransitModeSnapshot snapshot, {
    required double? latitude,
    required double? longitude,
  }) {
    final destination = snapshot.destinationStop;
    if (!snapshot.isActive ||
        destination == null ||
        latitude == null ||
        longitude == null) {
      return snapshot;
    }

    final metersToDestination = Geolocator.distanceBetween(
      latitude,
      longitude,
      destination.latitude,
      destination.longitude,
    );
    final movingAway = _movingAwayDetector.update(metersToDestination);

    // Only override when confident and not already flagged, and never after the
    // wake has fired (the rider may legitimately walk away from the stop then).
    if (movingAway &&
        snapshot.tripConcern == null &&
        snapshot.directionLocked &&
        !_approachAlarmTriggered) {
      return snapshot.copyWith(tripConcern: TripPatternConcern.wrongDirection);
    }
    return snapshot;
  }

  TransitModeSnapshot _stabilizeSnapshot(TransitModeSnapshot rawSnapshot) {
    if (!rawSnapshot.isActive ||
        rawSnapshot.currentStop == null ||
        rawSnapshot.destinationStop == null ||
        rawSnapshot.route == null) {
      return rawSnapshot;
    }

    final routeId = rawSnapshot.route!.routeId;
    final maxStepsPerFix = TransitWakeTuning.maxStepsPerFix(
      vehicleType: rawSnapshot.vehicleType,
      highConfidence: rawSnapshot.directionLocked,
    );
    final stabilizedStop = _stopProgressTracker.reconcile(
      routeId: routeId,
      destinationStop: rawSnapshot.destinationStop!,
      rawStop: rawSnapshot.currentStop!,
      routeStops: _transitModeService.routeStopsFor(
        routeId,
        destinationStop: rawSnapshot.destinationStop,
        anchorStop: rawSnapshot.currentStop,
        lockedPatternKey: _transitModeService.tripSession.lockedPatternKey,
      ),
      maxStepsPerFix: maxStepsPerFix,
    );

    if (stabilizedStop == rawSnapshot.currentStop) {
      return rawSnapshot;
    }

    return _transitModeService.rebuildSnapshotWithCurrentStop(
      snapshot: rawSnapshot,
      currentStop: stabilizedStop,
      routeId: routeId,
    );
  }

  @override
  void dispose() {
    _monitoringProvider.removeListener(_handleMonitoringChanged);
    super.dispose();
  }
}

extension on TransitModeSnapshot {
  TransitModeSnapshot copyWith({
    bool? gpsStale,
    double? alongRouteRemainingMeters,
    String? tripConcern,
    bool? directionConfirming,
  }) {
    return TransitModeSnapshot(
      isActive: isActive,
      agency: agency,
      route: route,
      vehicleType: vehicleType,
      destinationStop: destinationStop,
      currentStop: currentStop,
      previousStop: previousStop,
      nextStop: nextStop,
      stopsRemaining: stopsRemaining,
      alongRouteRemainingMeters:
          alongRouteRemainingMeters ?? this.alongRouteRemainingMeters,
      offRouteMeters: offRouteMeters,
      usesDistanceFallback: usesDistanceFallback,
      gpsStale: gpsStale ?? this.gpsStale,
      status: gpsStale == true ? 'GPS signal weak' : status,
      tripConcern: tripConcern ?? this.tripConcern,
      directionLabel: directionLabel,
      directionLocked: directionLocked,
      directionConfirming: directionConfirming ?? this.directionConfirming,
    );
  }
}

/// Detects a sustained increase in distance to the destination stop.
///
/// Requires several consecutive growing fixes and a meaningful cumulative
/// increase while comfortably away from the stop, so ordinary GPS jitter or a
/// route that briefly curves away from the destination does not trip a false
/// "wrong direction" warning.
class _MovingAwayDetector {
  static const _minAwayMeters = 800.0;
  static const _requiredIncreases = 4;
  static const _minCumulativeGrowthMeters = 250.0;
  static const _perFixNoiseMeters = 15.0;

  double? _lastMeters;
  int _increaseStreak = 0;
  double _cumulativeGrowth = 0;

  void reset() {
    _lastMeters = null;
    _increaseStreak = 0;
    _cumulativeGrowth = 0;
  }

  bool update(double meters) {
    final last = _lastMeters;
    _lastMeters = meters;
    if (last == null) {
      return false;
    }

    if (meters > last + _perFixNoiseMeters) {
      _increaseStreak++;
      _cumulativeGrowth += meters - last;
    } else if (meters < last - _perFixNoiseMeters) {
      _increaseStreak = 0;
      _cumulativeGrowth = 0;
    }

    return meters >= _minAwayMeters &&
        _increaseStreak >= _requiredIncreases &&
        _cumulativeGrowth >= _minCumulativeGrowthMeters;
  }
}
