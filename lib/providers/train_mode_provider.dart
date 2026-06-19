import 'package:flutter/material.dart';

import '../models/train_mode_snapshot.dart';
import '../models/train_mode_wake_setting.dart';
import '../services/settings_service.dart';
import '../services/train_mode_service.dart';
import 'monitoring_provider.dart';

class TrainModeProvider extends ChangeNotifier {
  TrainModeProvider(
    this._trainModeService,
    this._settingsService,
    this._monitoringProvider,
  ) {
    _monitoringProvider.addListener(_handleMonitoringChanged);
  }

  final TrainModeService _trainModeService;
  final SettingsService _settingsService;
  final MonitoringProvider _monitoringProvider;

  TrainModeSnapshot _snapshot = TrainModeSnapshot.inactive;
  String? _activeRouteId;
  bool _approachAlarmTriggered = false;

  TrainModeSnapshot get snapshot => _snapshot;
  bool get isActive => _snapshot.isActive;
  bool get shouldUseDistanceFallback =>
      _settingsService.settings.trainModeEnabled && !_snapshot.isActive;

  bool get shouldTriggerApproachAlarm {
    if (!_settingsService.settings.trainModeEnabled || !_snapshot.isActive) {
      return false;
    }

    if (_approachAlarmTriggered) {
      return false;
    }

    final wakeCount = _settingsService.settings.trainModeWake.wakeStationCount;
    return _snapshot.stationsRemaining <= wakeCount;
  }

  String get approachAlarmMessage {
    final destinationName =
        _snapshot.destinationStation?.stopName ?? 'your destination';
    return 'Approaching $destinationName\nWake up.';
  }

  void updateFromLocation({
    required double? latitude,
    required double? longitude,
  }) {
    if (!_settingsService.settings.trainModeEnabled) {
      if (_snapshot.isActive) {
        _snapshot = TrainModeSnapshot.inactive;
        notifyListeners();
      }
      return;
    }

    final nextSnapshot = _trainModeService.evaluate(
      destination: _monitoringProvider.selectedDestination,
      latitude: latitude,
      longitude: longitude,
      routeId: _activeRouteId,
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

  void _handleMonitoringChanged() {
    if (_monitoringProvider.selectedDestination == null) {
      _snapshot = TrainModeSnapshot.inactive;
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
