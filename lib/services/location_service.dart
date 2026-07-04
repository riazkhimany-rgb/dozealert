import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/current_location.dart';
import '../models/location_tracking_mode.dart';
import '../utils/app_log.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

class LocationService {
  static const _lastKnownMaxAge = Duration(minutes: 5);
  static const _prewarmInterval = Duration(seconds: 5);
  static const _prewarmDistanceFilter = 5;
  static const _monitoringInterval = Duration(seconds: 2);
  static const _monitoringDistanceFilter = 2;

  final StreamController<CurrentLocation> _controller =
      StreamController<CurrentLocation>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  LocationTrackingMode _mode = LocationTrackingMode.prewarm;
  bool _tracking = false;
  bool _navigationPriority = false;

  Stream<CurrentLocation> get locationStream => _controller.stream;

  bool get isTracking => _tracking;

  bool get isPrewarming =>
      _tracking && _mode == LocationTrackingMode.prewarm;

  bool get isMonitoring =>
      _tracking && _mode == LocationTrackingMode.monitoring;

  Future<LocationPermissionStatus> requestPermission() async {
    final currentStatus = await Permission.locationWhenInUse.status;
    if (currentStatus.isGranted) {
      return LocationPermissionStatus.granted;
    }

    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      return LocationPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }

    return LocationPermissionStatus.denied;
  }

  Future<LocationPermissionStatus> requestBackgroundPermission() async {
    if (!Platform.isAndroid) {
      return LocationPermissionStatus.granted;
    }

    final whenInUseStatus = await Permission.locationWhenInUse.status;
    if (!whenInUseStatus.isGranted) {
      final requested = await Permission.locationWhenInUse.request();
      if (!requested.isGranted) {
        return requested.isPermanentlyDenied
            ? LocationPermissionStatus.permanentlyDenied
            : LocationPermissionStatus.denied;
      }
    }

    final backgroundStatus = await Permission.locationAlways.status;
    if (backgroundStatus.isGranted) {
      return LocationPermissionStatus.granted;
    }

    final requestedBackground = await Permission.locationAlways.request();
    if (requestedBackground.isGranted) {
      return LocationPermissionStatus.granted;
    }
    if (requestedBackground.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }

    return LocationPermissionStatus.denied;
  }

  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Low-rate GPS warm-up while a destination is selected.
  Future<void> startPrewarm({bool navigationPriority = false}) async {
    await _startStream(
      mode: LocationTrackingMode.prewarm,
      navigationPriority: navigationPriority,
    );
  }

  Future<void> startTracking({
    bool highAccuracy = false,
    LocationTrackingMode mode = LocationTrackingMode.monitoring,
    bool navigationPriority = true,
  }) async {
    await _startStream(
      mode: mode,
      navigationPriority: navigationPriority || mode == LocationTrackingMode.monitoring,
    );
  }

  Future<void> setNavigationPriority(bool enabled) async {
    if (!_tracking || _navigationPriority == enabled) {
      return;
    }

    await _startStream(mode: _mode, navigationPriority: enabled);
  }

  Future<void> stopPrewarm() async {
    if (_tracking && _mode == LocationTrackingMode.prewarm) {
      await stopTracking();
    }
  }

  Future<void> stopTracking() async {
    _tracking = false;
    _navigationPriority = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<CurrentLocation?> fetchLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        return null;
      }

      final location = _locationFromPosition(position);
      final age = DateTime.now().difference(location.timestamp);
      if (age > _lastKnownMaxAge) {
        return null;
      }

      return location;
    } catch (error) {
      AppLog.d('LocationService: fetchLastKnownLocation failed: $error');
      return null;
    }
  }

  Future<CurrentLocation?> fetchCurrentLocation({
    bool highAccuracy = true,
    bool navigationPriority = false,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _oneShotSettings(
          navigationPriority: navigationPriority || highAccuracy,
        ),
      );

      return _locationFromPosition(position);
    } on LocationServiceDisabledException {
      rethrow;
    } on PermissionDeniedException {
      rethrow;
    } catch (error) {
      AppLog.d('LocationService: fetchCurrentLocation failed: $error');
      return null;
    }
  }

  Future<void> _startStream({
    required LocationTrackingMode mode,
    required bool navigationPriority,
  }) async {
    if (_tracking &&
        _mode == LocationTrackingMode.monitoring &&
        mode == LocationTrackingMode.prewarm) {
      return;
    }

    if (_tracking) {
      await stopTracking();
    }

    _tracking = true;
    _mode = mode;
    _navigationPriority = navigationPriority;

    final lastKnown = await fetchLastKnownLocation();
    if (lastKnown != null) {
      _emitLocation(lastKnown);
    }

    await _emitCurrentLocation(navigationPriority: navigationPriority);

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _streamSettings(
        mode: mode,
        navigationPriority: navigationPriority,
      ),
    ).listen(
      (position) => _emitLocation(_locationFromPosition(position)),
      onError: (Object error) {
        AppLog.d('LocationService: position stream error: $error');
      },
    );
  }

  Future<void> _emitCurrentLocation({required bool navigationPriority}) async {
    if (!_tracking) {
      return;
    }

    try {
      final location = await fetchCurrentLocation(
        navigationPriority: navigationPriority,
      );
      if (location != null) {
        _emitLocation(location);
      }
    } on LocationServiceDisabledException {
      rethrow;
    } on PermissionDeniedException {
      rethrow;
    }
  }

  LocationSettings _oneShotSettings({required bool navigationPriority}) {
    final accuracy = navigationPriority
        ? LocationAccuracy.bestForNavigation
        : LocationAccuracy.high;

    return LocationSettings(
      accuracy: accuracy,
      timeLimit: const Duration(seconds: 12),
    );
  }

  LocationSettings _streamSettings({
    required LocationTrackingMode mode,
    required bool navigationPriority,
  }) {
    final useNavigation = navigationPriority ||
        mode == LocationTrackingMode.monitoring;
    final accuracy = useNavigation
        ? LocationAccuracy.bestForNavigation
        : LocationAccuracy.high;
    final interval = mode == LocationTrackingMode.monitoring
        ? _monitoringInterval
        : _prewarmInterval;
    final distanceFilter = mode == LocationTrackingMode.monitoring
        ? _monitoringDistanceFilter
        : _prewarmDistanceFilter;

    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: interval,
      );
    }

    return AppleSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      activityType: useNavigation
          ? ActivityType.automotiveNavigation
          : ActivityType.other,
    );
  }

  CurrentLocation _locationFromPosition(Position position) {
    return CurrentLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      heading: position.heading,
    );
  }

  void _emitLocation(CurrentLocation location) {
    if (!_tracking || _controller.isClosed) {
      return;
    }

    _controller.add(location);
  }

  void dispose() {
    unawaited(stopTracking());
    unawaited(_controller.close());
  }
}
