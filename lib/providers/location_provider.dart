import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/arrival_context.dart';
import '../models/current_location.dart';
import '../models/monitoring_state.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../providers/trip_history_provider.dart';
import '../services/alarm_service.dart';
import '../services/background_monitor_service.dart';
import '../services/location_service.dart';
import '../services/monitoring_storage_service.dart';
import '../services/settings_service.dart';
import '../services/trip_history_service.dart';
import '../utils/app_log.dart';
import '../utils/gps_quality.dart';

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
    this._transitModeProvider,
    this._tripHistoryService, {
    this._tripHistoryProvider,
  }) {
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
  final TransitModeProvider _transitModeProvider;
  final TripHistoryService _tripHistoryService;
  final TripHistoryProvider? _tripHistoryProvider;

  final GpsQualityGate _gpsQualityGate = const GpsQualityGate();
  final GpsPositionSmoother _gpsSmoother = GpsPositionSmoother();

  StreamSubscription<CurrentLocation>? _locationSubscription;
  StreamSubscription<CurrentLocation>? _backgroundLocationSubscription;
  StreamSubscription<void>? _arrivalSubscription;

  CurrentLocation? _currentLocation;
  double _distanceRemainingMeters = 0;
  double _distanceRemainingKm = 0;
  double? _tripStartDistanceMeters;
  bool _trackingEnabled = false;
  bool _distanceIsStale = false;
  bool _usingAlongRouteDistance = false;
  bool _arrivalDialogVisible = false;
  bool _usingBackgroundService = false;
  bool _awaitingFreshLocation = false;
  DateTime? _monitoringStartedAt;
  double _closestApproachMeters = double.infinity;
  ArrivalContext? _arrivalContext;

  CurrentLocation? get currentLocation => _currentLocation;
  double get distanceRemainingMeters => _distanceRemainingMeters;
  double get distanceRemainingKm => _distanceRemainingKm;
  bool get distanceIsStale => _distanceIsStale;
  bool get usingAlongRouteDistance => _usingAlongRouteDistance;
  double? get tripProgressFraction {
    final start = _tripStartDistanceMeters;
    if (start == null || start <= 0 || !distanceIsReady) {
      return null;
    }

    return (1 - (_distanceRemainingMeters / start)).clamp(0.0, 1.0);
  }
  bool get distanceIsReady =>
      _trackingEnabled && !_awaitingFreshLocation && _currentLocation != null;
  bool get trackingEnabled => _trackingEnabled;
  bool get arrivalDialogVisible => _arrivalDialogVisible;
  ArrivalContext? get arrivalContext => _arrivalContext;
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

    await _monitoringStorage.setArrivalTriggered(false);
    if (!resume) {
      final startedAt = DateTime.now();
      _monitoringStartedAt = startedAt;
      await _monitoringStorage.markMonitoringStarted(startedAt);
      _resetLocationState(awaitingFresh: true);
    } else {
      _monitoringStartedAt = await _monitoringStorage.loadMonitoringStartedAt();
      _awaitingFreshLocation = false;
    }

    _monitoringProvider.startMonitoring();

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
      await _locationService.startTracking(highAccuracy: true);
    } on LocationServiceDisabledException {
      await _backgroundMonitorService.stopMonitoring();
      return LocationStartResult.locationServiceDisabled;
    } on PermissionDeniedException {
      await _backgroundMonitorService.stopMonitoring();
      return LocationStartResult.permissionDenied;
    }

    _transitModeProvider.resetApproachAlarm();
    _closestApproachMeters = double.infinity;
    _trackingEnabled = true;
    await _tripHistoryService.startTrip(destination.name);
    await _backgroundMonitorService.syncServiceState();
    unawaited(_bootstrapLocation());
    notifyListeners();
    return LocationStartResult.success;
  }

  Future<void> _bootstrapLocation() async {
    final lastKnown = await _locationService.fetchLastKnownLocation();
    if (lastKnown != null) {
      await _onLocationUpdate(lastKnown, allowStale: true);
    }

    await refreshLocation();
  }

  Future<void> stopTracking() async {
    if (!_trackingEnabled && !_alarmService.alarmActive) {
      return;
    }

    if (_alarmService.alarmActive) {
      await _alarmService.stopAlarm();
    }

    if (_monitoringProvider.currentState == MonitoringState.monitoring) {
      await _tripHistoryService.endTrip();
      await _tripHistoryProvider?.refresh();
    }

    _arrivalDialogVisible = false;
    _transitModeProvider.resetApproachAlarm();
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    _resetLocationState();
    await _monitoringStorage.clearSession();
    _monitoringProvider.stopMonitoring();
    notifyListeners();
  }

  Future<void> dismissArrival() async {
    await _alarmService.stopAlarm();
    await _tripHistoryService.recordAlarmDismissed();
    await _tripHistoryProvider?.refresh();
    _arrivalDialogVisible = false;
    _arrivalContext = null;
    _transitModeProvider.resetApproachAlarm();
    await _monitoringStorage.setArrivalTriggered(false);
    _monitoringProvider.resetToIdle();
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    _resetLocationState();
    await _monitoringStorage.clearSession();
    notifyListeners();
  }

  void _resetLocationState({bool awaitingFresh = false}) {
    _currentLocation = null;
    _distanceRemainingMeters = 0;
    _distanceRemainingKm = 0;
    _tripStartDistanceMeters = null;
    _closestApproachMeters = double.infinity;
    _distanceIsStale = false;
    _usingAlongRouteDistance = false;
    _gpsSmoother.reset();
    _awaitingFreshLocation = awaitingFresh;
    if (!awaitingFresh) {
      _monitoringStartedAt = null;
    }
  }

  bool _isStaleLocation(CurrentLocation location) {
    final startedAt = _monitoringStartedAt;
    if (startedAt == null) {
      return false;
    }

    return location.timestamp.isBefore(startedAt);
  }

  void updateDistance() {
    final destination = _monitoringProvider.selectedDestination;
    final current = _currentLocation;
    final transitSnapshot = _transitModeProvider.displaySnapshot;

    if (destination == null || current == null || _awaitingFreshLocation) {
      _distanceRemainingMeters = 0;
      _distanceRemainingKm = 0;
      _usingAlongRouteDistance = false;
      return;
    }

    final alongRouteRemaining = transitSnapshot.alongRouteRemainingMeters;
    final useAlongRoute = _settingsService.settings.transitModeEnabled &&
        transitSnapshot.isActive &&
        alongRouteRemaining != null;

    if (useAlongRoute) {
      _distanceRemainingMeters = alongRouteRemaining;
      _usingAlongRouteDistance = true;
    } else {
      _distanceRemainingMeters = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        destination.latitude,
        destination.longitude,
      );
      _usingAlongRouteDistance = false;
    }

    _distanceRemainingKm = _distanceRemainingMeters / 1000;

    if (_trackingEnabled &&
        _tripStartDistanceMeters == null &&
        _distanceRemainingMeters > 0) {
      _tripStartDistanceMeters = _distanceRemainingMeters;
    }

    if (_trackingEnabled &&
        _monitoringProvider.currentState == MonitoringState.monitoring) {
      _closestApproachMeters = _distanceRemainingMeters < _closestApproachMeters
          ? _distanceRemainingMeters
          : _closestApproachMeters;
    }
  }

  Future<void> _onLocationUpdate(
    CurrentLocation location, {
    bool allowStale = false,
  }) async {
    if (_awaitingFreshLocation && _isStaleLocation(location) && !allowStale) {
      return;
    }

    final allowDegraded = _settingsService.settings.transitModeEnabled &&
        _transitModeProvider.isActive;
    if (!_gpsQualityGate.accept(location, allowDegraded: allowDegraded)) {
      if (_trackingEnabled && _distanceRemainingMeters > 0) {
        _distanceIsStale = true;
        notifyListeners();
      }
      return;
    }

    if (_awaitingFreshLocation) {
      _awaitingFreshLocation = false;
    }

    final smoothed = _gpsSmoother.smooth(location);
    _currentLocation = smoothed;
    _distanceIsStale = false;
    _transitModeProvider.updateFromLocation(
      latitude: smoothed.latitude,
      longitude: smoothed.longitude,
      headingDegrees: smoothed.hasHeading ? smoothed.heading : null,
      speedMps: smoothed.speed >= 0 ? smoothed.speed : null,
    );
    updateDistance();

    final destination = _monitoringProvider.selectedDestination;
    if (destination != null && _usingBackgroundService) {
      await _backgroundMonitorService.updateNotification(
        destinationName: destination.name,
        distanceKm: _distanceRemainingKm,
      );
    }

    await _checkArrival();
    await _checkMissedStop();
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
    await _tripHistoryService.recordAlarmTriggered();
    _setArrivalContext(
      usedTransitMode: false,
      detailMessage: 'Distance wake — within wake radius',
    );
    _monitoringProvider.markArrived();
    _arrivalDialogVisible = true;
    notifyListeners();
  }

  Future<void> _checkArrival() async {
    if (!_trackingEnabled || _awaitingFreshLocation) {
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

    if (_settingsService.settings.transitModeEnabled) {
      if (_transitModeProvider.shouldTriggerApproachAlarm) {
        await _monitoringStorage.setArrivalTriggered(true);
        final message = _transitModeProvider.approachAlarmMessage;
        await _alarmService.playApproachAlarm(
          title: 'Transit Mode Alert',
          body: message,
        );
        await _tripHistoryService.recordAlarmTriggered();
        _transitModeProvider.markApproachAlarmTriggered();
        _setArrivalContext(
          usedTransitMode: true,
          detailMessage: message,
        );
        _monitoringProvider.markArrived();
        _arrivalDialogVisible = true;
        notifyListeners();
        return;
      }

      if (_transitModeProvider.isActive) {
        return;
      }

      // Distance fallback when transit mode cannot place the user on the route.
    }

    final thresholdMeters = _settingsService.settings.testModeEnabled
        ? _testModeArrivalThresholdMeters
        : _monitoringProvider.radiusMeters.toDouble();

    if (_distanceRemainingMeters > thresholdMeters) {
      return;
    }

    await _monitoringStorage.setArrivalTriggered(true);
    await _alarmService.playAlarm();
    await _tripHistoryService.recordAlarmTriggered();
    _setArrivalContext(
      usedTransitMode: false,
      detailMessage: _settingsService.settings.transitModeEnabled
          ? 'Distance wake — transit fallback'
          : 'Distance wake — within wake radius',
    );
    _monitoringProvider.markArrived();
    _arrivalDialogVisible = true;
    notifyListeners();
  }

  void _setArrivalContext({
    required bool usedTransitMode,
    required String detailMessage,
  }) {
    final destination = _monitoringProvider.selectedDestination;
    _arrivalContext = ArrivalContext(
      destinationName: destination?.name ?? 'Destination',
      usedTransitMode: usedTransitMode,
      detailMessage: detailMessage,
      distanceKm: _distanceRemainingKm,
      stopsRemaining: usedTransitMode
          ? _transitModeProvider.snapshot.stopsRemaining
          : null,
    );
  }

  Future<void> _checkMissedStop() async {
    if (!_trackingEnabled || _awaitingFreshLocation) {
      return;
    }

    if (_monitoringProvider.currentState != MonitoringState.monitoring) {
      return;
    }

    if (_alarmService.alarmActive || _arrivalDialogVisible) {
      return;
    }

    final radiusMeters = _monitoringProvider.radiusMeters.toDouble();
    final approached = _closestApproachMeters <= radiusMeters * 3;
    final movingAway = _distanceRemainingMeters > radiusMeters &&
        _distanceRemainingMeters > _closestApproachMeters + 200;

    if (!approached || !movingAway) {
      return;
    }

    await _handleMissedStop();
  }

  Future<void> _handleMissedStop() async {
    await _tripHistoryService.recordMissedTrip();
    await _tripHistoryProvider?.refresh();
    _monitoringProvider.markMissed();
    _arrivalDialogVisible = false;
    _arrivalContext = null;
    await _alarmService.stopAlarm();
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    _resetLocationState();
    await _monitoringStorage.clearSession();
    notifyListeners();
  }

  Future<void> refreshLocation() async {
    try {
      final location = await _locationService.fetchCurrentLocation();
      if (location != null) {
        await _onLocationUpdate(location);
        return;
      }

      final lastKnown = await _locationService.fetchLastKnownLocation();
      if (lastKnown != null) {
        await _onLocationUpdate(lastKnown, allowStale: true);
      }
    } catch (error) {
      AppLog.d('LocationProvider: refreshLocation failed: $error');
    }
  }

  Future<void> developerTriggerAlarm() async {
    await _alarmService.playAlarm();
    await _tripHistoryService.recordAlarmTriggered();
    notifyListeners();
  }

  Future<void> developerStopAlarm() async {
    await _alarmService.stopAlarm();
    notifyListeners();
  }

  Future<void> developerSimulateArrival() async {
    if (_monitoringProvider.currentState == MonitoringState.monitoring) {
      await _monitoringStorage.setArrivalTriggered(true);
    }
    await _alarmService.playAlarm();
    await _tripHistoryService.recordAlarmTriggered();
    if (_monitoringProvider.currentState == MonitoringState.monitoring) {
      _monitoringProvider.markArrived();
    }
    _arrivalDialogVisible = true;
    notifyListeners();
  }

  void developerSimulateOneStopRemaining() {
    _transitModeProvider.simulateOneStopRemaining();
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
