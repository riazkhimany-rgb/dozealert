import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/current_location.dart';
import '../models/monitoring_state.dart';
import '../providers/monitoring_provider.dart';
import '../services/alarm_service.dart';
import '../services/background_monitor_service.dart';
import '../services/location_service.dart';
import '../services/monitoring_storage_service.dart';
import '../services/settings_service.dart';

enum LocationStartResult {
  success,
  noDestination,
  permissionDenied,
  permissionPermanentlyDenied,
  backgroundPermissionDenied,
  locationServiceDisabled,
  foregroundServiceFailure,
  batteryOptimizationRequired,
}

class LocationProvider extends ChangeNotifier {
  LocationProvider(
    this._locationService,
    this._monitoringProvider,
    this._alarmService,
    this._settingsService,
    this._backgroundMonitorService,
    this._monitoringStorage,
  ) {
    _locationSubscription = _locationService.locationStream.listen(
      _onLocationUpdate,
    );
    _backgroundLocationSubscription =
        _backgroundMonitorService.locationStream.listen(_onLocationUpdate);
    _arrivalSubscription =
        _backgroundMonitorService.arrivalStream.listen((_) {
      unawaited(_handleBackgroundArrival());
    });
    _monitoringProvider.addListener(_onMonitoringChanged);
  }

  static const _testModeArrivalThresholdMeters = 5000.0;

  final LocationService _locationService;
  final MonitoringProvider _monitoringProvider;
  final AlarmService _alarmService;
  final SettingsService _settingsService;
  final BackgroundMonitorService _backgroundMonitorService;
  final MonitoringStorageService _monitoringStorage;

  StreamSubscription<CurrentLocation>? _locationSubscription;
  StreamSubscription<CurrentLocation>? _backgroundLocationSubscription;
  StreamSubscription<void>? _arrivalSubscription;

  CurrentLocation? _currentLocation;
  double _distanceRemainingMeters = 0;
  double _distanceRemainingKm = 0;
  bool _trackingEnabled = false;
  bool _arrivalDialogVisible = false;
  bool _usingBackgroundService = false;

  CurrentLocation? get currentLocation => _currentLocation;
  double get distanceRemainingMeters => _distanceRemainingMeters;
  double get distanceRemainingKm => _distanceRemainingKm;
  bool get trackingEnabled => _trackingEnabled;
  bool get arrivalDialogVisible => _arrivalDialogVisible;
  bool get usingBackgroundService => _usingBackgroundService;

  BackgroundMonitorDiagnostics get backgroundDiagnostics =>
      _backgroundMonitorService.diagnostics;

  bool get hasDestination => _monitoringProvider.selectedDestination != null;

  Future<void> resumeMonitoringIfNeeded() async {
    final session = await _monitoringStorage.loadSession();
    if (session == null || !session.isActive) {
      return;
    }

    if (_monitoringProvider.selectedDestination == null) {
      await _monitoringStorage.clearSession();
      return;
    }

    if (session.state == MonitoringState.monitoring &&
        !_trackingEnabled) {
      await startTracking(resume: true);
    }
  }

  Future<void> syncBackgroundState() async {
    await _backgroundMonitorService.syncServiceState();
    notifyListeners();
  }

  Future<LocationStartResult> startTracking({bool resume = false}) async {
    if (_monitoringProvider.selectedDestination == null) {
      return LocationStartResult.noDestination;
    }

    if (_trackingEnabled) {
      return LocationStartResult.success;
    }

    final permission = await _locationService.requestPermission();
    switch (permission) {
      case LocationPermissionStatus.granted:
        break;
      case LocationPermissionStatus.denied:
        return LocationStartResult.permissionDenied;
      case LocationPermissionStatus.permanentlyDenied:
        return LocationStartResult.permissionPermanentlyDenied;
    }

    if (Platform.isAndroid) {
      final backgroundPermission =
          await _locationService.requestBackgroundPermission();
      switch (backgroundPermission) {
        case LocationPermissionStatus.granted:
          break;
        case LocationPermissionStatus.denied:
          return LocationStartResult.backgroundPermissionDenied;
        case LocationPermissionStatus.permanentlyDenied:
          return LocationStartResult.backgroundPermissionDenied;
      }

      if (!resume &&
          await _backgroundMonitorService.isBatteryOptimizationEnabled()) {
        return LocationStartResult.batteryOptimizationRequired;
      }
    }

    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStartResult.locationServiceDisabled;
    }

    final destination = _monitoringProvider.selectedDestination!;

    if (Platform.isAndroid) {
      final backgroundResult = await _backgroundMonitorService.startMonitoring(
        destinationName: destination.name,
      );
      switch (backgroundResult) {
        case BackgroundMonitorStartResult.success:
          _usingBackgroundService = true;
        case BackgroundMonitorStartResult.unsupportedPlatform:
          _usingBackgroundService = false;
        case BackgroundMonitorStartResult.notificationPermissionDenied:
          return LocationStartResult.foregroundServiceFailure;
        case BackgroundMonitorStartResult.foregroundServiceFailure:
          return LocationStartResult.foregroundServiceFailure;
      }
    } else {
      _usingBackgroundService = false;
    }

    try {
      if (!_usingBackgroundService) {
        await _locationService.startTracking();
      }
    } on LocationServiceDisabledException {
      await _backgroundMonitorService.stopMonitoring();
      return LocationStartResult.locationServiceDisabled;
    } on PermissionDeniedException {
      await _backgroundMonitorService.stopMonitoring();
      return LocationStartResult.permissionDenied;
    }

    await _monitoringStorage.setArrivalTriggered(false);
    _trackingEnabled = true;
    _monitoringProvider.startMonitoring();
    await _backgroundMonitorService.syncServiceState();
    notifyListeners();
    return LocationStartResult.success;
  }

  Future<void> stopTracking() async {
    if (!_trackingEnabled && !_alarmService.alarmActive) {
      return;
    }

    if (_alarmService.alarmActive) {
      await _alarmService.stopAlarm();
    }

    _arrivalDialogVisible = false;
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    await _monitoringStorage.clearSession();
    _monitoringProvider.stopMonitoring();
    notifyListeners();
  }

  Future<void> dismissArrival() async {
    await _alarmService.stopAlarm();
    _arrivalDialogVisible = false;
    await _monitoringStorage.setArrivalTriggered(false);
    _monitoringProvider.resetToIdle();
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    await _monitoringStorage.clearSession();
    notifyListeners();
  }

  void updateDistance() {
    final destination = _monitoringProvider.selectedDestination;
    final current = _currentLocation;

    if (destination == null || current == null) {
      _distanceRemainingMeters = 0;
      _distanceRemainingKm = 0;
      return;
    }

    _distanceRemainingMeters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      destination.latitude,
      destination.longitude,
    );
    _distanceRemainingKm = _distanceRemainingMeters / 1000;
  }

  Future<void> _onLocationUpdate(CurrentLocation location) async {
    _currentLocation = location;
    updateDistance();

    final destination = _monitoringProvider.selectedDestination;
    if (destination != null && _usingBackgroundService) {
      await _backgroundMonitorService.updateNotification(
        destinationName: destination.name,
        distanceKm: _distanceRemainingKm,
      );
    }

    await _checkArrival();
    notifyListeners();
  }

  void _onMonitoringChanged() {
    updateDistance();

    if (_monitoringProvider.selectedDestination == null) {
      unawaited(stopTracking());
    }

    notifyListeners();
  }

  Future<void> _handleBackgroundArrival() async {
    if (!_trackingEnabled) {
      return;
    }

    if (_monitoringProvider.currentState != MonitoringState.monitoring) {
      return;
    }

    if (_alarmService.alarmActive) {
      return;
    }

    await _alarmService.playAlarm();
    _monitoringProvider.markArrived();
    _arrivalDialogVisible = true;
    notifyListeners();
  }

  Future<void> _checkArrival() async {
    if (!_trackingEnabled) {
      return;
    }

    if (_monitoringProvider.currentState != MonitoringState.monitoring) {
      return;
    }

    if (_alarmService.alarmActive) {
      return;
    }

    if (_currentLocation == null) {
      return;
    }

    if (await _monitoringStorage.isArrivalTriggered()) {
      return;
    }

    final thresholdMeters = _settingsService.settings.testModeEnabled
        ? _testModeArrivalThresholdMeters
        : _monitoringProvider.radiusMeters.toDouble();

    if (_distanceRemainingMeters > thresholdMeters) {
      return;
    }

    await _monitoringStorage.setArrivalTriggered(true);
    await _alarmService.playAlarm();
    _monitoringProvider.markArrived();
    _arrivalDialogVisible = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _backgroundLocationSubscription?.cancel();
    _arrivalSubscription?.cancel();
    _monitoringProvider.removeListener(_onMonitoringChanged);
    super.dispose();
  }
}
