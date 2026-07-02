import 'dart:async';

import 'package:flutter/material.dart';

import '../models/background_transit_pattern.dart';
import '../models/monitoring_state.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_stop.dart';
import '../services/monitoring_storage_service.dart';
import '../services/settings_service.dart';
import '../services/transit_mode_service.dart';
import '../services/transit_stop_progress_tracker.dart';
import '../utils/transit_wake_message.dart';
import 'monitoring_provider.dart';

class TransitModeProvider extends ChangeNotifier {
  TransitModeProvider(
    this._transitModeService,
    this._settingsService,
    this._monitoringProvider,
    this._monitoringStorage,
  ) {
    _monitoringProvider.addListener(_handleMonitoringChanged);
  }

  final TransitModeService _transitModeService;
  final SettingsService _settingsService;
  final MonitoringProvider _monitoringProvider;
  final MonitoringStorageService _monitoringStorage;
  final TransitStopProgressTracker _stopProgressTracker =
      TransitStopProgressTracker();

  TransitModeSnapshot _snapshot = TransitModeSnapshot.inactive;
  TransitModeSnapshot? _lastActiveSnapshot;
  String? _activeRouteId;
  bool _approachAlarmTriggered = false;

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

  /// Route stops from the user's current stop through the destination, inclusive.
  List<TransitStop> get routeSegmentStops =>
      _routeSegmentStopsFor(displaySnapshot);

  List<TransitStop> _routeSegmentStopsFor(TransitModeSnapshot source) {
    final route = source.route;
    final current = source.currentStop;
    final destination = source.destinationStop;
    if (!source.isActive || route == null || current == null || destination == null) {
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

    if (!_transitModeService.tripSession.isDirectionLocked ||
        !_stopProgressTracker.hasEstablishedProgress) {
      return false;
    }

    if (_snapshot.hasTripConcern) {
      return false;
    }

    final wakeCount =
        _settingsService.settings.transitModeWake.wakeStopCount;

    if (_snapshot.stopsRemaining <= wakeCount) return true;

    // Safety net for atDestination: the progress tracker advances at most
    // +1 stop per GPS fix. If GPS becomes noisy or sparse exactly at the
    // destination, stopsRemaining may stick at 1 while the user is physically
    // at (or has just passed) their stop. Fire the alarm so they are not
    // silently missed.
    if (wakeCount == 0 && _snapshot.stopsRemaining == 1) {
      final offRoute = _snapshot.offRouteMeters;
      // Only apply the fallback when the user is close enough to be plausibly
      // on the platform (within 400 m of the route — same threshold used for
      // on-route snapping elsewhere in the app).
      if (offRoute != null && offRoute <= 400) return true;
    }

    return false;
  }

  /// Copy for the current approach alarm, based on wake-by-stops setting.
  WakeAlertCopy get approachAlarmCopy {
    return TransitWakeMessage.forTransitAlarm(
      snapshot: _snapshot,
      wakeSetting: _settingsService.settings.transitModeWake,
      segmentStops: routeSegmentStops,
      fallbackDestinationName:
          _monitoringProvider.selectedDestination?.name,
    );
  }

  void updateFromLocation({
    required double? latitude,
    required double? longitude,
    double? headingDegrees,
    double? speedMps,
  }) {
    if (!_settingsService.settings.transitModeEnabled) {
      if (_snapshot.isActive || _lastActiveSnapshot != null) {
        _snapshot = TransitModeSnapshot.inactive;
        _lastActiveSnapshot = null;
        _stopProgressTracker.reset();
        _transitModeService.resetTripSession();
        notifyListeners();
      }
      return;
    }

    final rawSnapshot = _transitModeService.evaluate(
      destination: _monitoringProvider.selectedDestination,
      latitude: latitude,
      longitude: longitude,
      routeId: _activeRouteId,
      maxStopProximityMeters: TransitModeService.routeStopMatchMeters,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
    );
    final nextSnapshot = _stabilizeSnapshot(rawSnapshot);

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
      segmentStops: _routeSegmentStopsFor(snapshot),
      fallbackDestinationName:
          _monitoringProvider.selectedDestination?.name,
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

    final segmentStops = _routeSegmentStopsFor(snapshot);
    final destination = snapshot.destinationStop;
    final route = snapshot.route;
    final current = snapshot.currentStop;
    if (segmentStops.length >= 2 && destination != null && route != null) {
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
      if (_snapshot.isActive || _approachAlarmTriggered || _lastActiveSnapshot != null) {
        _snapshot = TransitModeSnapshot.inactive;
        _lastActiveSnapshot = null;
        _approachAlarmTriggered = false;
        _stopProgressTracker.reset();
        _transitModeService.resetTripSession();
        notifyListeners();
      }
      return;
    }

    if (_monitoringProvider.selectedDestination != null) {
      _approachAlarmTriggered = false;
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
      _transitModeService.resetTripSession();
      unawaited(_monitoringStorage.clearTransitBackgroundSnapshot());
      notifyListeners();
      return;
    }

    _approachAlarmTriggered = false;
    _stopProgressTracker.reset();
    _transitModeService.resetTripSession();
    updateFromLocation(
      latitude: null,
      longitude: null,
    );
  }

  TransitModeSnapshot _stabilizeSnapshot(TransitModeSnapshot rawSnapshot) {
    if (!rawSnapshot.isActive ||
        rawSnapshot.currentStop == null ||
        rawSnapshot.destinationStop == null ||
        rawSnapshot.route == null) {
      return rawSnapshot;
    }

    final routeId = rawSnapshot.route!.routeId;
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
      tripConcern: tripConcern,
      directionLabel: directionLabel,
      directionLocked: directionLocked,
    );
  }
}
