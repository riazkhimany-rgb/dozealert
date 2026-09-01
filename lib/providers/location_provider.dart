import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/arrival_context.dart';
import '../models/current_location.dart';
import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../models/transit_mode_wake_setting.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../providers/trip_history_provider.dart';
import '../models/location_tracking_mode.dart';
import '../services/activity_recognition_service.dart';
import '../services/alarm_service.dart';
import '../services/background_monitor_service.dart';
import '../services/ios_locked_reliability_service.dart';
import '../services/location_service.dart';
import '../services/monitoring_storage_service.dart';
import '../services/settings_service.dart';
import '../services/trip_diagnostics_log.dart';
import '../services/trip_history_service.dart';
import '../utils/app_log.dart';
import '../utils/gps_quality.dart';
import '../utils/transit_wake_message.dart';
import '../utils/trip_ux_copy.dart';

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
    if (Platform.isIOS) {
      _iosRegionSubscription = _alarmService.iosReliability.regionEntered.listen(
        (regionId) => unawaited(_handleIosGeofenceEntry(regionId)),
      );
    }
  }

  static const _prewarmIdleTimeout = Duration(minutes: 8);
  static const _prewarmFixMaxAge = Duration(minutes: 2);

  static const _testModeArrivalThresholdMeters = 5000.0;

  /// How often the native wake copy is refreshed for a locked-phone geofence.
  static const _nativeTripInfoInterval = Duration(seconds: 30);

  /// How long stop counting may sit frozen before the distance wake takes over.
  static const _stopTrackingStaleAfter = Duration(seconds: 90);
  static const _transitWakeWatchdogInterval = Duration(seconds: 15);

  /// Only gaps this long are worth a diagnostics entry.
  static const _fixGapLogThreshold = Duration(seconds: 30);

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
  StreamSubscription<String>? _iosRegionSubscription;
  bool _iosPreAlertShown = false;
  DateTime? _lastNativeTripInfoAt;
  DateTime? _lastAcceptedFixAt;
  Duration _lastFixGap = Duration.zero;
  int? _lastStopsRemaining;
  DateTime? _lastStopCountChangeAt;

  StreamSubscription<CurrentLocation>? _locationSubscription;
  StreamSubscription<CurrentLocation>? _backgroundLocationSubscription;
  StreamSubscription<void>? _arrivalSubscription;
  StreamSubscription<bool>? _activitySubscription;
  StreamSubscription<bool>? _onFootActivitySubscription;
  Timer? _prewarmIdleTimer;
  Timer? _transitWakeWatchdogTimer;

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
    await _adoptNativeWakeIfFired();
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

    if (Platform.isIOS) {
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

      // Wake alerts rely on notification + background audio on iOS.
      await _alarmService.ensureNotificationPermission();
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

      // Android: clear any prewarm-seeded transit progress before FGS loads
      // prefs. A stale "on route at destination" snapshot would wake immediately
      // on Start. Mid-trip FGS evaluation is unchanged.
      if (Platform.isAndroid) {
        await _monitoringStorage.setTransitOnRouteActive(false);
        await _monitoringStorage.clearTransitBackgroundSnapshot();
        _transitModeProvider.resetProgressForMonitoringStart();
      }
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
      // iOS: no FGS — Always permission + Geolocator AppleSettings background
      // stream (see LocationService._streamSettings).
      _usingBackgroundService = false;
    }

    if (_startTrackingWasCancelled(startGeneration)) {
      await _rollbackFailedStart();
      return LocationStartResult.cancelled;
    }

    _transitModeProvider.resetApproachAlarm();
    _closestApproachMeters = double.infinity;
    _iosPreAlertShown = false;
    _trackingEnabled = true;

    try {
      await _stopGpsPrewarm();
      final useBackgroundGpsStream =
          Platform.isAndroid && _usingBackgroundService;
      if (!useBackgroundGpsStream) {
        // Android FGS owns GPS when running; iOS always uses this stream.
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

    unawaited(
      TripDiagnosticsLog.record('trip.start', {
        'destination': destination.name,
        'transitMode': _settingsService.settings.transitModeEnabled,
        'radiusMeters': _monitoringProvider.radiusMeters,
        'backgroundService': _usingBackgroundService,
      }),
    );

    if (Platform.isIOS) {
      // Keep-alive first: everything below depends on the process surviving
      // the screen lock.
      await _alarmService.iosReliability.startKeepAlive();
      // Geofences before trip info: an immediate "already inside" callback then
      // finds no active trip and cannot wake the rider at the platform.
      await _armIosGeofences(destination);
      await _refreshIosNativeTripInfo(destination.name, force: true);
      await _alarmService.updateTripHeartbeatNotification(
        destinationName: destination.name,
        statusDetail: TripUxCopy.findingLocation,
        force: true,
      );
    }

    await _tripHistoryService.startTrip(destination.name);
    await _backgroundMonitorService.syncServiceState();
    _startTransitWakeWatchdog();
    unawaited(_bootstrapLocation());
    notifyListeners();
    return LocationStartResult.success;
  }

  void _startTransitWakeWatchdog() {
    _transitWakeWatchdogTimer?.cancel();
    _transitWakeWatchdogTimer = Timer.periodic(
      _transitWakeWatchdogInterval,
      (_) => unawaited(
        _checkArrival(
          allowWhileEstablishingGps: true,
          countStableArmFix: false,
        ),
      ),
    );
  }

  void _stopTransitWakeWatchdog() {
    _transitWakeWatchdogTimer?.cancel();
    _transitWakeWatchdogTimer = null;
  }

  Future<void> _bootstrapLocation() async {
    final prewarmFix = _recentPrewarmLocation();
    if (prewarmFix != null) {
      await _onLocationUpdate(prewarmFix, allowStale: true);
    }

    // Never seed stop progress from lastKnown on trip start. A cached fix near
    // the destination the rider just picked (or visited) locks "at destination"
    // and fires the wake before live GPS snaps onto the route. Live fixes only.
    // (FGS mid-trip stream is unchanged — it does not emit lastKnown.)
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
    _iosPreAlertShown = false;
    unawaited(TripDiagnosticsLog.record('trip.stop'));
    _stopTransitWakeWatchdog();
    await _activityRecognitionService.stopListening();
    await _locationService.stopTracking();
    await _disarmIosTripAids();
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
    await _disarmIosTripAids();
    await _backgroundMonitorService.stopMonitoring();
    _usingBackgroundService = false;
    _monitoringProvider.stopMonitoring();
    _trackingEnabled = false;
    notifyListeners();
  }

  bool _startTrackingWasCancelled(int startGeneration) =>
      startGeneration != _startTrackingGeneration;

  Future<void> dismissArrival() async {
    unawaited(TripDiagnosticsLog.record('alarm.dismissed'));
    await _alarmService.stopAlarm();
    await _tripHistoryService.recordAlarmDismissed();
    await _tripHistoryProvider?.refresh();
    _arrivalDialogVisible = false;
    _arrivalContext = null;
    _transitModeProvider.resetApproachAlarm();
    await _monitoringStorage.setArrivalTriggered(false);
    _monitoringProvider.resetToIdle();
    _stopTransitWakeWatchdog();
    await _activityRecognitionService.stopListening();
    await _locationService.stopTracking();
    await _disarmIosTripAids();
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
    _lastAcceptedFixAt = null;
    _lastFixGap = Duration.zero;
    _lastStopsRemaining = null;
    _lastStopCountChangeAt = null;
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

    // iOS Core Location: negative horizontalAccuracy means the fix is invalid.
    // Geolocator can surface that as accuracy < 0; never treat it as "perfect".
    if (Platform.isIOS && location.accuracy < 0) {
      return;
    }

    // Cached/stale fixes may only seed direction — never lock stop progress
    // (otherwise lastKnown near the destination zeros stops-remaining / wakes).
    final staleProgressGuard = allowStale && _isStaleLocation(location);

    final routeActive = _transitModeProvider.isActive;
    final bootstrapPhase = _awaitingFreshLocation ||
        (_settingsService.settings.transitModeEnabled &&
            _monitoringProvider.selectedDestination != null &&
            !routeActive);
    final allowDegraded = _settingsService.settings.transitModeEnabled &&
        (bootstrapPhase || routeActive);
    final positionOk = !staleProgressGuard &&
        _gpsQualityGate.accept(
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
    _trackFixFreshness();

    final destination = _monitoringProvider.selectedDestination;
    if (destination != null && _usingBackgroundService) {
      final transitSnapshot = _transitModeProvider.displaySnapshot;
      // FGS already publishes stop-based notification text on each fix; km here
      // would overwrite "N stops remaining" during an on-route transit trip.
      if (!transitSnapshot.isActive || !transitSnapshot.directionLocked) {
        await _backgroundMonitorService.updateNotification(
          destinationName: destination.name,
          distanceKm: _distanceRemainingKm,
        );
      }
    }

    if (Platform.isIOS && destination != null && _trackingEnabled) {
      await _adoptNativeWakeIfFired();
      await _refreshIosNativeTripInfo(destination.name);
      await _updateIosTripHeartbeat(destination.name);
      await _maybeShowIosPreAlert(destination.name);
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

  Future<void> _checkArrival({
    bool allowWhileEstablishingGps = false,
    bool countStableArmFix = true,
  }) async {
    if (!_trackingEnabled) {
      return;
    }

    if (_monitoringProvider.currentState != MonitoringState.monitoring) {
      return;
    }

    if (_alarmService.alarmActive) {
      return;
    }

    if (await _monitoringStorage.isArrivalTriggered()) {
      return;
    }

    final establishingGps = _awaitingFreshLocation;
    final shouldTransitWake = _settingsService.settings.transitModeEnabled &&
        _transitModeProvider.shouldTriggerApproachAlarm(
          countStableArmFix: countStableArmFix,
        );

    // Stop-based wakes can use last-known progress (poor-GPS grace), including
    // while acquiring a fresh fix. Distance wakes still need a live location.
    if (_currentLocation == null && !shouldTransitWake) {
      return;
    }

    final thresholdMeters = _settingsService.settings.testModeEnabled
        ? _testModeArrivalThresholdMeters
        : _monitoringProvider.radiusMeters.toDouble();

    if (_settingsService.settings.transitModeEnabled) {
      if (shouldTransitWake) {
        await _monitoringStorage.setArrivalTriggered(true);
        await TripDiagnosticsLog.record('wake.fired', {
          'source': 'stops',
          'stopsRemaining':
              _transitModeProvider.displaySnapshot.stopsRemaining,
          'wakeReason':
              _transitModeProvider.lastWakeDecisionReason?.name ?? '',
        });
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

      if (establishingGps && !allowWhileEstablishingGps) {
        return;
      }

      if (_transitModeProvider.isActive ||
          _transitModeProvider.isTransitTrackableDestination ||
          _transitModeProvider.gpsSignalLost) {
        // Normally we wait for the stop counter (or route lock) rather than
        // firing a straight-line wake. Weak GPS can freeze that counter, so
        // fall through to the distance wake once it has clearly gone stale and
        // we are already inside the wake radius.
        if (!_stopTrackingIsStale() || !_insideDistanceWake(thresholdMeters)) {
          return;
        }
        AppLog.d(
          'LocationProvider: stop tracking stale — using distance wake',
        );
        await TripDiagnosticsLog.record('stops.stale-fallback', {
          'lastFixGapS': _lastFixGap.inSeconds,
          'stopsRemaining': _lastStopsRemaining,
          'distanceM': _distanceRemainingMeters.round(),
        });
      }

      // Distance fallback for map-pin destinations when not on a transit route.
    } else if (establishingGps && !allowWhileEstablishingGps) {
      return;
    }

    if (establishingGps || _currentLocation == null) {
      return;
    }

    if (_distanceRemainingMeters > thresholdMeters) {
      return;
    }

    await _monitoringStorage.setArrivalTriggered(true);
    await TripDiagnosticsLog.record('wake.fired', {
      'source': 'distance',
      'distanceM': _distanceRemainingMeters.round(),
      'thresholdM': thresholdMeters.round(),
    });
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

  void _trackFixFreshness() {
    final now = DateTime.now();
    final previousFix = _lastAcceptedFixAt;
    _lastFixGap =
        previousFix == null ? Duration.zero : now.difference(previousFix);
    _lastAcceptedFixAt = now;

    if (_trackingEnabled && _lastFixGap >= _fixGapLogThreshold) {
      unawaited(
        TripDiagnosticsLog.record('gps.gap', {
          'seconds': _lastFixGap.inSeconds,
          'accuracy': _currentLocation?.accuracy.round(),
        }),
      );
    }

    final stops = _transitModeProvider.isActive
        ? _transitModeProvider.snapshot.stopsRemaining
        : null;
    if (stops != _lastStopsRemaining || _lastStopCountChangeAt == null) {
      if (_trackingEnabled && stops != _lastStopsRemaining) {
        unawaited(
          TripDiagnosticsLog.record('stops.change', {
            'from': _lastStopsRemaining,
            'to': stops,
            'distanceM': _distanceRemainingMeters.round(),
          }),
        );
      }
      _lastStopsRemaining = stops;
      _lastStopCountChangeAt = now;
    }
  }

  /// True when stop tracking cannot be trusted: either fixes stopped arriving,
  /// or we still have no usable stop count long after the trip began.
  ///
  /// A known count that simply has not changed does *not* count as stale — a
  /// bus dwelling in traffic must not trigger an early wake.
  bool _stopTrackingIsStale() {
    if (_lastFixGap >= _stopTrackingStaleAfter) {
      return true;
    }

    final stops = _lastStopsRemaining;
    if (stops != null && stops >= 0) {
      return false;
    }

    final lastChange = _lastStopCountChangeAt;
    return lastChange != null &&
        DateTime.now().difference(lastChange) >= _stopTrackingStaleAfter;
  }

  bool _insideDistanceWake(double thresholdMeters) =>
      distanceIsReady &&
      !_distanceIsStale &&
      _distanceRemainingMeters <= thresholdMeters;

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
    await _disarmIosTripAids();
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

      // Do not fall back to lastKnown — it falsely arms stop wakes at Start.
      // Wait for the next live stream / FGS fix instead.
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

  Future<void> _armIosGeofences(Destination destination) async {
    final wakeMeters = _monitoringProvider.radiusMeters.toDouble();
    final approachMeters = math.max(wakeMeters * 1.5, 250.0);
    final destinationMeters = math.max(wakeMeters, 150.0);
    await _alarmService.iosReliability.startGeofences(
      latitude: destination.latitude,
      longitude: destination.longitude,
      approachRadiusMeters: approachMeters,
      destinationRadiusMeters: destinationMeters,
    );
  }

  Future<void> _disarmIosTripAids() async {
    if (!Platform.isIOS) {
      return;
    }
    _iosPreAlertShown = false;
    _lastNativeTripInfoAt = null;
    final reliability = _alarmService.iosReliability;
    await reliability.stopGeofences();
    await reliability.clearTripInfo();
    await reliability.stopNativeAlarm();
    await reliability.stopKeepAlive();
    await _alarmService.clearTripHeartbeatNotification();
  }

  /// Mirrors the current wake copy into native storage so a geofence entry can
  /// raise the alarm without waking the Dart isolate.
  Future<void> _refreshIosNativeTripInfo(
    String destinationName, {
    bool force = false,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    final now = DateTime.now();
    final last = _lastNativeTripInfoAt;
    if (!force && last != null && now.difference(last) < _nativeTripInfoInterval) {
      return;
    }
    _lastNativeTripInfoAt = now;

    final copy = _currentWakeCopy(destinationName);
    final transitStopsWake = _settingsService.settings.transitModeEnabled &&
        (_transitModeProvider.isActive ||
            _transitModeProvider.isTransitTrackableDestination);
    await _alarmService.iosReliability.setTripInfo(
      destinationName: destinationName,
      alarmTitle: copy.headline,
      alarmBody: copy.detailMessage,
      criticalAlerts: _alarmService.criticalAlertsGranted,
      resetWake: force,
      // Distance geofences are a backup for map-pin trips. For wake-by-stops,
      // only Dart (with keep-alive) may start the alarm — otherwise a 1 km
      // radius fires the tone one or two stops early with stale copy.
      nativeWakeEnabled: !transitStopsWake,
    );
  }

  /// Call after the rider changes wake-by-stops / alert distance mid-trip.
  Future<void> onWakeSettingsChanged() async {
    if (!Platform.isIOS || !_trackingEnabled) {
      return;
    }
    final destination = _monitoringProvider.selectedDestination;
    if (destination == null) {
      return;
    }
    await _refreshIosNativeTripInfo(destination.name, force: true);
    await TripDiagnosticsLog.record('settings.wake.changed', {
      'wakeStops': _settingsService.settings.transitModeWake.wakeStopCount,
      'transitMode': _settingsService.settings.transitModeEnabled,
    });
  }

  WakeAlertCopy _currentWakeCopy(String destinationName) {
    if (_settingsService.settings.transitModeEnabled &&
        (_transitModeProvider.isActive ||
            _transitModeProvider.isTransitTrackableDestination)) {
      return _transitModeProvider.approachAlarmCopy;
    }
    return TransitWakeMessage.forDistanceAlarm(
      destinationName: destinationName,
      transitFallback: _settingsService.settings.transitModeEnabled,
    );
  }

  /// Adopts a wake that native code already fired while Dart was suspended.
  ///
  /// Wake-by-stops trips never arm native auto-wake; if a stale flag remains,
  /// silence it and evaluate through the same [_checkArrival] path Android uses.
  Future<void> _adoptNativeWakeIfFired() async {
    if (!Platform.isIOS || !_trackingEnabled) {
      return;
    }
    if (!await _alarmService.iosReliability.consumeNativeWake()) {
      return;
    }

    if (_usingTransitStopsWake()) {
      AppLog.d(
        'LocationProvider: ignoring native iOS wake — using shared stop trigger',
      );
      await _alarmService.iosReliability.stopNativeAlarm();
      await TripDiagnosticsLog.record('wake.native.ignored', {
        'reason': 'transit-stops',
      });
      await _checkArrival();
      return;
    }

    AppLog.d('LocationProvider: adopting native iOS wake');
    await TripDiagnosticsLog.record('wake.native.adopted');
    await _triggerIosGeofenceWake(nativeAlreadyFired: true);
  }

  Future<void> _updateIosTripHeartbeat(String destinationName) async {
    final statusDetail = _heartbeatStatusDetail();
    await _alarmService.updateTripHeartbeatNotification(
      destinationName: destinationName,
      statusDetail: statusDetail,
    );
  }

  String _heartbeatStatusDetail() {
    if (_settingsService.settings.transitModeEnabled &&
        _transitModeProvider.isActive) {
      final stops = _transitModeProvider.displaySnapshot.stopsRemaining;
      if (stops >= 0) {
        return TripUxCopy.notificationStopsRemaining(stops);
      }
    }
    if (distanceIsReady) {
      return TripUxCopy.notificationKmRemaining(_distanceRemainingKm);
    }
    return TripUxCopy.findingLocation;
  }

  Future<void> _maybeShowIosPreAlert(String destinationName) async {
    if (_iosPreAlertShown || _alarmService.alarmActive) {
      return;
    }
    if (_monitoringProvider.currentState != MonitoringState.monitoring) {
      return;
    }

    final shouldPreAlert = _shouldShowIosPreAlert();
    if (!shouldPreAlert) {
      return;
    }

    _iosPreAlertShown = true;
    await TripDiagnosticsLog.record('prealert.shown', {
      'distanceM': distanceIsReady ? _distanceRemainingMeters.round() : null,
    });
    await _alarmService.showPreAlertNotification(
      title: TripUxCopy.gettingCloseTitle,
      body: TripUxCopy.gettingCloseBody(destinationName),
    );
  }

  bool _shouldShowIosPreAlert() {
    if (_settingsService.settings.transitModeEnabled &&
        _transitModeProvider.isActive) {
      final wakeCount =
          _settingsService.settings.transitModeWake.wakeStopCount;
      final stops = _transitModeProvider.snapshot.stopsRemaining;
      // One stop before the configured wake threshold.
      return stops == wakeCount + 1;
    }

    final threshold = _settingsService.settings.testModeEnabled
        ? _testModeArrivalThresholdMeters
        : _monitoringProvider.radiusMeters.toDouble();
    // Entering the outer approach band (2× wake radius).
    return distanceIsReady &&
        _distanceRemainingMeters <= threshold * 2 &&
        _distanceRemainingMeters > threshold;
  }

  Future<void> _handleIosGeofenceEntry(String regionId) async {
    if (!Platform.isIOS || !_trackingEnabled) {
      return;
    }
    if (_alarmService.alarmActive) {
      return;
    }
    if (_monitoringProvider.currentState != MonitoringState.monitoring) {
      return;
    }
    if (await _monitoringStorage.isArrivalTriggered()) {
      return;
    }

    AppLog.d('LocationProvider: iOS geofence entered $regionId');
    unawaited(
      TripDiagnosticsLog.record('geofence.enter', {
        'region': regionId,
        'distanceM': distanceIsReady ? _distanceRemainingMeters.round() : null,
      }),
    );

    final transitStops = _usingTransitStopsWake();

    // Approach ring: optional pre-alert. Wake-by-stops never fires from radius.
    if (regionId == IosLockedReliabilityService.approachRegionId) {
      final destinationName =
          _monitoringProvider.selectedDestination?.name ?? 'Destination';
      if (!_iosPreAlertShown) {
        _iosPreAlertShown = true;
        await _alarmService.showPreAlertNotification(
          title: TripUxCopy.gettingCloseTitle,
          body: TripUxCopy.gettingCloseBody(destinationName),
        );
      }
      if (transitStops) {
        await _checkArrival();
      } else if (distanceIsReady &&
          _distanceRemainingMeters <=
              _monitoringProvider.radiusMeters.toDouble()) {
        await _triggerIosGeofenceWake();
      }
      return;
    }

    if (regionId == IosLockedReliabilityService.destinationRegionId) {
      if (transitStops) {
        // Same decision path as Android: shared stop trigger via _checkArrival.
        // Geofence only nudges the isolate awake.
        await TripDiagnosticsLog.record('geofence.nudge', {
          'reason': 'transit-stops-check-arrival',
        });
        await _checkArrival();
        return;
      }
      await _triggerIosGeofenceWake();
    }
  }

  bool _usingTransitStopsWake() =>
      _settingsService.settings.transitModeEnabled &&
      (_transitModeProvider.isActive ||
          _transitModeProvider.isTransitTrackableDestination);

  /// Distance-mode / map-pin wake from an iOS geofence. Not used for wake-by-stops.
  Future<void> _triggerIosGeofenceWake({bool nativeAlreadyFired = false}) async {
    if (_usingTransitStopsWake()) {
      await _alarmService.iosReliability.stopNativeAlarm();
      await _checkArrival();
      return;
    }

    if (_alarmService.alarmActive ||
        await _monitoringStorage.isArrivalTriggered()) {
      if (nativeAlreadyFired) {
        // Dart already handled this arrival; silence the duplicate native tone.
        await _alarmService.iosReliability.stopNativeAlarm();
      }
      return;
    }

    await _monitoringStorage.setArrivalTriggered(true);
    final destinationName =
        _monitoringProvider.selectedDestination?.name ?? 'Destination';
    await TripDiagnosticsLog.record('wake.fired', {
      'source': nativeAlreadyFired ? 'native-geofence' : 'dart-geofence',
      'distanceM': distanceIsReady ? _distanceRemainingMeters.round() : null,
    });

    if (_settingsService.settings.transitModeEnabled &&
        (_transitModeProvider.isActive ||
            _transitModeProvider.isTransitTrackableDestination)) {
      final copy = _transitModeProvider.approachAlarmCopy;
      await _alarmService.playApproachAlarm(
        title: copy.headline,
        body: copy.detailMessage,
        ttsPhrase: copy.ttsPhrase,
      );
      await _tripHistoryService.recordAlarmTriggered();
      _transitModeProvider.markApproachAlarmTriggered();
      _setArrivalContext(usedTransitMode: true, copy: copy);
    } else {
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
      _setArrivalContext(usedTransitMode: false, copy: copy);
    }

    _monitoringProvider.markArrived();
    _arrivalDialogVisible = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _prewarmIdleTimer?.cancel();
    _stopTransitWakeWatchdog();
    _locationSubscription?.cancel();
    _backgroundLocationSubscription?.cancel();
    _arrivalSubscription?.cancel();
    _activitySubscription?.cancel();
    _onFootActivitySubscription?.cancel();
    _iosRegionSubscription?.cancel();
    _monitoringProvider.removeListener(_onMonitoringChanged);
    super.dispose();
  }
}
