import 'dart:async';

import 'package:flutter/material.dart';

import '../models/monitoring_state.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_stop.dart';
import '../services/monitoring_storage_service.dart';
import '../services/settings_service.dart';
import '../services/transit_mode_service.dart';
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
    );
  }

  bool get shouldUseDistanceFallback =>
      _settingsService.settings.transitModeEnabled && !_snapshot.isActive;

  bool get shouldTriggerApproachAlarm {
    if (!_settingsService.settings.transitModeEnabled || !_snapshot.isActive) {
      return false;
    }

    if (_approachAlarmTriggered) {
      return false;
    }

    final wakeCount =
        _settingsService.settings.transitModeWake.wakeStopCount;
    return _snapshot.stopsRemaining <= wakeCount;
  }

  String get approachAlarmMessage {
    final destinationName =
        _snapshot.destinationStop?.stopName ?? 'your destination';
    return 'Approaching $destinationName\nWake up.';
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
        notifyListeners();
      }
      return;
    }

    final nextSnapshot = _transitModeService.evaluate(
      destination: _monitoringProvider.selectedDestination,
      latitude: latitude,
      longitude: longitude,
      routeId: _activeRouteId,
      maxStopProximityMeters: TransitModeService.routeStopMatchMeters,
      headingDegrees: headingDegrees,
      speedMps: speedMps,
    );

    if (nextSnapshot.route?.routeId != null) {
      _activeRouteId = nextSnapshot.route!.routeId;
    }

    if (nextSnapshot.isActive) {
      _lastActiveSnapshot = nextSnapshot;
      if (nextSnapshot != _snapshot) {
        _snapshot = nextSnapshot;
        unawaited(_monitoringStorage.setTransitOnRouteActive(true));
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
      notifyListeners();
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
      notifyListeners();
      return;
    }

    _approachAlarmTriggered = false;
    updateFromLocation(
      latitude: null,
      longitude: null,
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
    );
  }
}
