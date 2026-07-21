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
import '../models/location_tracking_mode.dart';
import '../services/activity_recognition_service.dart';
import '../services/alarm_service.dart';
import '../services/background_monitor_service.dart';
import '../services/location_service.dart';
import '../services/monitoring_storage_service.dart';
import '../services/settings_service.dart';
import '../services/trip_history_service.dart';
import '../utils/app_log.dart';
import '../utils/gps_quality.dart';
import '../utils/transit_wake_message.dart';

enum LocationStartResult {
  success,
  cancelled,
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
    this._activityRecognitionService,
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
      (location) {
        if (_trackingEnabled) {
          unawaited(_onLocationUpdate(location));
          return;
        }
        if (_gpsPrewarming) {
          unawaited(_onPrewarmLocation(location));
        }
      },
    );
    _backgroundLocationSubscription =
        _backgroundMonitorService.locationStream.listen((location) {
      if (_trackingEnabled) {
        unawaited(_onLocationUpdate(location));
      }
    });
    _arrivalSubscription =
        _backgroundMonitorService.arrivalStream.listen((event) {
      unawaited(_handleBackgroundArrival(transitWake: event.transitWake));
    });
    _monitoringProvider.addListener(_onMonitoringChanged);
    _activitySubscription =
        _activityRecognitionService.vehicleActivityStream.listen(
      (_) => unawaited(_syncRiderMotionState()),
    );
    _onFootActivitySubscription =
        _activityRecognitionService.onFootActivityStream.listen(
      (_) => unawaited(_syncRiderMotionState()),
    );
  }

  static const _prewarmIdleTimeout = Duration(minutes: 8);
  static const _prewarmFixMaxAge = Duration(minutes: 2);

  static const _testModeArrivalThresholdMeters = 5000.0;

  final LocationService _locationService;
  final ActivityRecognitionService _activityRecognitionService;
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
  StreamSubscription<bool>? _activitySubscription;
  StreamSubscription<bool>? _onFootActivitySubscription;
  Timer? _prewarmIdleTimer;

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
  bool _gpsPrewarming = false;
  CurrentLocation? _lastPrewarmLocation;
  DateTime? _monitoringStartedAt;
  double _closestApproachMeters = double.infinity;
  ArrivalContext? _arrivalContext;
  int _startTrackingGeneration = 0;

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
  bool get establishingGps => _awaitingFreshLocation && _trackingEnabled;
  bool get gpsPrewarming => _gpsPrewarming && !_trackingEnabled;
  bool get trackingEnabled => _trackingEnabled;
  bool get arrivalDialogVisible => _arrivalDialogVisible;
  ArrivalContext? get arrivalContext => _arrivalContext;
  bool get usingBackgroundService => _usingBackgroundService;

  DateTime? get lastLocationFixAt => _currentLocation?.timestamp;

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
      return;
    }

    if (_monitoringProvider.selectedDestination != null && !_trackingEnabled) {
      await _beginGpsPrewarm();
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

    final startGeneration = _startTrackingGeneration;

    if (_trackingEnabled) {
      if (_monitoringProvider.isMonitoring) {
        return LocationStartResult.success;
      }

      // GPS was left running without an active monitoring session — restart cleanly.
      await _locationService.stopTracking();
      await _activityRecognitionService.stopListening();
      _trackingEnabled = false;
      _usingBackgroundService = false;
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
    final recentPrewarmFix = _recentPrewarmLocation();
    if (!resume) {
      final startedAt = DateTime.now();
      _monitoringStartedAt = startedAt;
      await _monitoringStorage.markMonitoringStarted(startedAt);
      _resetLocationState(awaitingFresh: recentPrewarmFix == null);
    } else {
      _monitoringStartedAt = await _monitoringStorage.loadMonitoringStartedAt();
      _awaitingFreshLocation = false;
    }

    await _monitoringProvider.startMonitoring();

    if (_startTrackingWasCancelled(startGeneration)) {
      await _rollbackFailedStart();
      return LocationStartResult.cancelled;
    }

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
          await _rollbackFailedStart();
          return LocationStartResult.foregroundServiceFailure;
        case BackgroundMonitorStartResult.foregroundServiceFailure:
          await _rollbackFailedStart();
          return LocationStartResult.foregroundServiceFailure;
      }
    } else {
      _usingBackgroundService = false;
    }

    if (_startTrackingWasCancelled(startGeneration)) {
      await _rollbackFailedStart();
      return LocationStartResult.cancelled;
    }

    _transitModeProvider.resetApproachAlarm();
    _closestApproachMeters = double.infinity;
    _trackingEnabled = true;

    try {
      await _stopGpsPrewarm();
      final useBackgroundGpsStream =
          Platform.isAndroid && _usingBackgroundService;
      if (!useBackgroundGpsStream) {
        await _locationService.startTracking(
          highAccuracy: true,
          mode: LocationTrackingMode.monitoring,
          navigationPriority: true,
        );
      }
      if (_settingsService.settings.activityRecognitionEnabled) {
        await _activityRecognitionService.startListening();
        unawaited(_syncRiderMotionState());
      }
    } on LocationServiceDisabledException {
      await _rollbackFailedStart();
      return LocationStartResult.locationServiceDisabled;
    } on PermissionDeniedException {
      await _rollbackFailedStart();
      return LocationStartResult.permissionDenied;
    }

    if (_startTrackingWasCancelled(startGeneration)) {
      await _rollbackFailedStart();
      return LocationStartResult.cancelled;
    }

    await _tripHistoryService.startTrip(destination.name);
    await _backgroundMonitorService.syncServiceState();
    unawaited(_bootstrapLocation());
    notifyListeners();
    return LocationStartResult.success;
  }

  Future<void> _bootstrapLocation() async {
    final prewarmFix = _recentPrewarmLocation();
    if (prewarmFix != null) {
      await _onLocationUpdate(prewarmFix, allowStale: true);
    }

    final lastKnown = await _locationService.fetchLastKnownLocation();
    if (lastKnown != null) {
      await _onLocationUpdate(lastKnown, allowStale: true);
    }

    await refreshLocation();
  }

  CurrentLocation? _recentPrewarmLocation() {
    final fix = _lastPrewarmLocation;
    if (fix == null) {
      return null;
    }

    if (DateTime.now().difference(fix.timestamp) > _prewarmFixMaxAge) {
      return null;
    }

    return fix;
  }

  Future<void> stopTracking() async {
    _startTrackingGeneration++;

    if (!_shouldProcessStopTracking()) {
      return;
    }

    if (_alarmService.alarmActive) {
      await _alarmService.stopAlarm();
    }

    final monitoringState = _monitoringProvider.currentState;
    if (monitoringState == MonitoringState.monitoring ||
        monitoringState == MonitoringState.arrived) {
      await _tripHistoryService.endTrip();
      await _tripHistoryProvider?.refresh();
    }

    _arrivalDialogVisible = false;
    _transitModeProvider.resetApproachAlarm();
    await _activityRecognitionService.stopListening();
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    _resetLocationState();
    await _monitoringStorage.clearSession();
    _monitoringProvider.stopMonitoring();
    notifyListeners();
  }

  bool _shouldProcessStopTracking() {
    if (_trackingEnabled || _alarmService.alarmActive) {
      return true;
    }

    final state = _monitoringProvider.currentState;
    if (state == MonitoringState.monitoring ||
        state == MonitoringState.arrived ||
        state == MonitoringState.missed) {
      return true;
    }

    return _backgroundMonitorService.isForegroundServiceRunning ||
        _backgroundMonitorService.isBackgroundMonitoringEnabled;
  }

  Future<void> _rollbackFailedStart() async {
    await _backgroundMonitorService.stopMonitoring();
    _usingBackgroundService = false;
    _monitoringProvider.stopMonitoring();
    _trackingEnabled = false;
    notifyListeners();
  }

  bool _startTrackingWasCancelled(int startGeneration) =>
      startGeneration != _startTrackingGeneration;

  Future<void> dismissArrival() async {
    await _alarmService.stopAlarm();
    await _tripHistoryService.recordAlarmDismissed();
    await _tripHistoryProvider?.refresh();
    _arrivalDialogVisible = false;
    _arrivalContext = null;
    _transitModeProvider.resetApproachAlarm();
    await _monitoringStorage.setArrivalTriggered(false);
    _monitoringProvider.resetToIdle();
    await _activityRecognitionService.stopListening();
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    _resetLocationState();
    await _monitoringStorage.clearSession();
    notifyListeners();

    if (_monitoringProvider.selectedDestination != null) {
      unawaited(_beginGpsPrewarm());
    }
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
    _gpsPrewarming = false;
    if (!awaitingFresh) {
      _lastPrewarmLocation = null;
      _monitoringStartedAt = null;
    }
  }

  bool _isStaleLocation(CurrentLocation location) {
    final startedAt = _monitoringStartedAt;
    if (startedAt == null) {
      return false;
    }

    // Only reject clearly cached fixes from before the session — not live
    // stream updates whose GPS timestamp may trail clock time slightly.
    return location.timestamp.isBefore(
      startedAt.subtract(const Duration(seconds: 60)),
    );
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

    final routeActive = _transitModeProvider.isActive;
    final bootstrapPhase = _awaitingFreshLocation ||
        (_settingsService.settings.transitModeEnabled &&
            _monitoringProvider.selectedDestination != null &&
            !routeActive);
    final allowDegraded = _settingsService.settings.transitModeEnabled &&
        (bootstrapPhase || routeActive);
    final positionOk = _gpsQualityGate.accept(
      location,
      allowDegraded: allowDegraded,
    );
    final inferenceOk = bootstrapPhase
        ? _gpsQualityGate.acceptForBootstrap(location)
        : _gpsQualityGate.acceptForDirectionInference(location);

    if (!positionOk && !inferenceOk) {
      if (_trackingEnabled && _distanceRemainingMeters > 0) {
        _distanceIsStale = true;
        notifyListeners();
      }
      return;
    }

    if (!positionOk && inferenceOk) {
      _transitModeProvider.updateFromLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        headingDegrees: location.hasHeading ? location.heading : null,
        speedMps: location.speed >= 0 ? location.speed : null,
        accuracyMeters: location.accuracy,
        directionInferenceOnly: true,
        fixTimestamp: location.timestamp,
      );
      notifyListeners();
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
      accuracyMeters: smoothed.accuracy,
      fixTimestamp: smoothed.timestamp,
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
      unawaited(_stopGpsPrewarm());
      unawaited(stopTracking());
      return;
    }

    if (!_trackingEnabled) {
      unawaited(_beginGpsPrewarm());
    }

    notifyListeners();
  }

  Future<void> _beginGpsPrewarm() async {
    if (_trackingEnabled || _monitoringProvider.selectedDestination == null) {
      return;
    }

    try {
      final permission = await _locationService.requestPermission();
      if (permission != LocationPermissionStatus.granted) {
        return;
      }

      if (!await _locationService.isLocationServiceEnabled()) {
        return;
      }

      _prewarmIdleTimer?.cancel();
      _prewarmIdleTimer = Timer(_prewarmIdleTimeout, () {
        unawaited(_stopGpsPrewarm());
      });

      if (_gpsPrewarming && _locationService.isPrewarming) {
        await _syncLocationPriority();
        return;
      }

      if (_settingsService.settings.activityRecognitionEnabled) {
        await _activityRecognitionService.startListening();
      }
      await _locationService.startPrewarm(
        navigationPriority: true,
      );
      _gpsPrewarming = true;
      notifyListeners();
    } catch (error) {
      AppLog.d('LocationProvider: prewarm failed: $error');
    }
  }

  Future<void> _stopGpsPrewarm() async {
    _prewarmIdleTimer?.cancel();
    _prewarmIdleTimer = null;
    if (!_gpsPrewarming && !_locationService.isPrewarming) {
      return;
    }

    _gpsPrewarming = false;
    await _locationService.stopPrewarm();
    if (!_trackingEnabled) {
      await _activityRecognitionService.stopListening();
      await _monitoringStorage.saveRiderMotionState(
        inVehicle: null,
        onFoot: null,
      );
    }
    notifyListeners();
  }

  Future<void> _syncRiderMotionState() async {
    if (!_settingsService.settings.activityRecognitionEnabled) {
      await _monitoringStorage.saveRiderMotionState(
        inVehicle: null,
        onFoot: null,
      );
      return;
    }

    await _monitoringStorage.saveRiderMotionState(
      inVehicle: _activityRecognitionService.activityInVehicleHint,
      onFoot: _activityRecognitionService.activityOnFootHint,
    );
    await _syncLocationPriority();
  }

  Future<void> _syncLocationPriority() async {
    if (!_locationService.isTracking) {
      return;
    }

    final navigationPriority = !_settingsService.settings.activityRecognitionEnabled
        ? true
        : _activityRecognitionService.inVehicle;
    if (_trackingEnabled) {
      await _locationService.setNavigationPriority(navigationPriority);
      return;
    }

    if (_gpsPrewarming) {
      await _locationService.startPrewarm(
        navigationPriority: navigationPriority,
      );
    }
  }

  Future<void> _onPrewarmLocation(CurrentLocation location) async {
    if (_trackingEnabled ||
        _monitoringProvider.selectedDestination == null ||
        !_gpsPrewarming) {
      return;
    }

    _lastPrewarmLocation = location;

    final positionOk = _gpsQualityGate.accept(
      location,
      allowDegraded: _settingsService.settings.transitModeEnabled,
    );
    final inferenceOk =
        _gpsQualityGate.acceptForDirectionInference(location);

    if (!positionOk && !inferenceOk) {
      return;
    }

    _transitModeProvider.updateFromLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      headingDegrees: location.hasHeading ? location.heading : null,
      speedMps: location.speed >= 0 ? location.speed : null,
      accuracyMeters: location.accuracy,
      directionInferenceOnly: !positionOk,
      fixTimestamp: location.timestamp,
    );
  }

  Future<void> _handleBackgroundArrival({bool transitWake = false}) async {
    if (!_trackingEnabled) {
      return;
    }

    if (_monitoringProvider.currentState != MonitoringState.monitoring) {
      return;
    }

    if (_alarmService.alarmActive) {
      return;
    }

    if (_settingsService.settings.transitModeEnabled) {
      if (!transitWake &&
          (_transitModeProvider.isActive ||
              _transitModeProvider.isTransitTrackableDestination)) {
        return;
      }
    }

    final destinationName =
        _monitoringProvider.selectedDestination?.name ?? 'Destination';

    if (transitWake) {
      final persistedStops = await _monitoringStorage.readTransitStopsRemaining();
      final copy = _transitModeProvider.approachAlarmCopyWith(
        stopsRemainingOverride:
            persistedStops >= 0 ? persistedStops : null,
      );
      await _alarmService.playApproachAlarm(
        title: copy.headline,
        body: copy.detailMessage,
        ttsPhrase: copy.ttsPhrase,
      );
      await _tripHistoryService.recordAlarmTriggered();
      _transitModeProvider.markApproachAlarmTriggered();
      _setArrivalContext(usedTransitMode: true, copy: copy);
      _monitoringProvider.markArrived();
      _arrivalDialogVisible = true;
      notifyListeners();
      return;
    }

    final copy = TransitWakeMessage.forDistanceAlarm(
      destinationName: destinationName,
    );
    await _alarmService.playApproachAlarm(
      title: copy.headline,
      body: copy.detailMessage,
      ttsPhrase: copy.ttsPhrase,
    );
    await _tripHistoryService.recordAlarmTriggered();
    _setArrivalContext(
      usedTransitMode: false,
      copy: copy,
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
        final copy = _transitModeProvider.approachAlarmCopy;
        await _alarmService.playApproachAlarm(
          title: copy.headline,
          body: copy.detailMessage,
          ttsPhrase: copy.ttsPhrase,
        );
        await _tripHistoryService.recordAlarmTriggered();
        _transitModeProvider.markApproachAlarmTriggered();
        _setArrivalContext(
          usedTransitMode: true,
          copy: copy,
        );
        _monitoringProvider.markArrived();
        _arrivalDialogVisible = true;
        notifyListeners();
        return;
      }

      if (_transitModeProvider.isActive) {
        return;
      }

      if (_transitModeProvider.isTransitTrackableDestination) {
        // GTFS stop destination — wait for route lock; no straight-line wake.
        return;
      }

      // Distance fallback for map-pin destinations when not on a transit route.
    }

    final thresholdMeters = _settingsService.settings.testModeEnabled
        ? _testModeArrivalThresholdMeters
        : _monitoringProvider.radiusMeters.toDouble();

    if (_distanceRemainingMeters > thresholdMeters) {
      return;
    }

    await _monitoringStorage.setArrivalTriggered(true);
    final destinationName =
        _monitoringProvider.selectedDestination?.name ?? 'Destination';
    final copy = TransitWakeMessage.forDistanceAlarm(
      destinationName: destinationName,
      transitFallback: _settingsService.settings.transitModeEnabled,
    );
    await _alarmService.playApproachAlarm(
      title: copy.headline,
      body: copy.detailMessage,
      ttsPhrase: copy.ttsPhrase,
    );
    await _tripHistoryService.recordAlarmTriggered();
    _setArrivalContext(
      usedTransitMode: false,
      copy: copy,
    );
    _monitoringProvider.markArrived();
    _arrivalDialogVisible = true;
    notifyListeners();
  }

  void _setArrivalContext({
    required bool usedTransitMode,
    required WakeAlertCopy copy,
  }) {
    _arrivalContext = ArrivalContext(
      destinationName: copy.primaryStopName,
      usedTransitMode: usedTransitMode,
      uiHeadline: copy.uiHeadline,
      headline: copy.headline,
      currentStopName: copy.currentStopName,
      detailMessage: copy.detailMessage,
      secondaryLine: copy.secondaryLine,
      wearSubline: copy.wearSubline,
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

    if (_settingsService.settings.transitModeEnabled &&
        _transitModeProvider.isActive) {
      if (_transitModeProvider.shouldFlagTransitMissedStop) {
        await _handleMissedStop(transitMissed: true);
      }
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

  Future<void> _handleMissedStop({bool transitMissed = false}) async {
    await _tripHistoryService.recordMissedTrip();
    await _tripHistoryProvider?.refresh();
    _monitoringProvider.markMissed();
    _arrivalDialogVisible = false;
    _arrivalContext = null;
    await _alarmService.stopAlarm();
    await _activityRecognitionService.stopListening();
    await _locationService.stopTracking();
    await _backgroundMonitorService.stopMonitoring();
    _trackingEnabled = false;
    _usingBackgroundService = false;
    _resetLocationState();
    await _monitoringStorage.clearTransitBackgroundSnapshot();
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

  Future<void> syncActivityRecognitionFromSettings() async {
    if (!_settingsService.settings.activityRecognitionEnabled) {
      await _activityRecognitionService.stopListening();
      await _syncRiderMotionState();
      return;
    }

    if (_trackingEnabled || _gpsPrewarming) {
      await _activityRecognitionService.startListening();
      unawaited(_syncRiderMotionState());
    }
  }

  @override
  void dispose() {
    _prewarmIdleTimer?.cancel();
    _locationSubscription?.cancel();
    _backgroundLocationSubscription?.cancel();
    _arrivalSubscription?.cancel();
    _activitySubscription?.cancel();
    _onFootActivitySubscription?.cancel();
    _monitoringProvider.removeListener(_onMonitoringChanged);
    super.dispose();
  }
}
