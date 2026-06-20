import 'package:flutter/material.dart';

import '../models/transit_mode_snapshot.dart';
import '../models/transit_mode_wake_setting.dart';
import '../services/settings_service.dart';
import '../services/transit_mode_service.dart';
import 'monitoring_provider.dart';

class TransitModeProvider extends ChangeNotifier {
  TransitModeProvider(
    this._transitModeService,
    this._settingsService,
    this._monitoringProvider,
  ) {
    _monitoringProvider.addListener(_handleMonitoringChanged);
  }

  final TransitModeService _transitModeService;
  final SettingsService _settingsService;
  final MonitoringProvider _monitoringProvider;

  TransitModeSnapshot _snapshot = TransitModeSnapshot.inactive;
  String? _activeRouteId;
  bool _approachAlarmTriggered = false;

  TransitModeSnapshot get snapshot => _snapshot;
  bool get isActive => _snapshot.isActive;
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
  }) {
    if (!_settingsService.settings.transitModeEnabled) {
      if (_snapshot.isActive) {
        _snapshot = TransitModeSnapshot.inactive;
        notifyListeners();
      }
      return;
    }

    final nextSnapshot = _transitModeService.evaluate(
      destination: _monitoringProvider.selectedDestination,
      latitude: latitude,
      longitude: longitude,
      routeId: _activeRouteId,
      maxStopProximityMeters: _monitoringProvider.radiusMeters,
    );

    if (nextSnapshot.route?.routeId != null) {
      _activeRouteId = nextSnapshot.route!.routeId;
    }

    if (nextSnapshot != _snapshot) {
      _snapshot = nextSnapshot;
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
      if (_snapshot.isActive || _approachAlarmTriggered) {
        _snapshot = TransitModeSnapshot.inactive;
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
    _approachAlarmTriggered = false;
    notifyListeners();
  }

  void _handleMonitoringChanged() {
    if (_monitoringProvider.selectedDestination == null) {
      _snapshot = TransitModeSnapshot.inactive;
      _activeRouteId = null;
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
