import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/current_location.dart';
import '../utils/app_log.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

class LocationService {
  static const _lastKnownMaxAge = Duration(minutes: 5);

  final StreamController<CurrentLocation> _controller =
      StreamController<CurrentLocation>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  bool _tracking = false;

  Stream<CurrentLocation> get locationStream => _controller.stream;

  bool get isTracking => _tracking;

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

  Future<void> startTracking({bool highAccuracy = false}) async {
    if (_tracking) {
      await stopTracking();
    }

    _tracking = true;

    final lastKnown = await fetchLastKnownLocation();
    if (lastKnown != null) {
      _emitLocation(lastKnown);
    }

    await _emitCurrentLocation(highAccuracy: highAccuracy);

    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: Platform.isAndroid
          ? AndroidSettings(
              accuracy: highAccuracy
                  ? LocationAccuracy.high
                  : LocationAccuracy.medium,
              distanceFilter: highAccuracy ? 3 : 5,
              intervalDuration: Duration(seconds: highAccuracy ? 3 : 5),
            )
          : AppleSettings(
              accuracy: highAccuracy
                  ? LocationAccuracy.high
                  : LocationAccuracy.medium,
              distanceFilter: highAccuracy ? 3 : 5,
            ),
    ).listen(
      (position) => _emitLocation(_locationFromPosition(position)),
      onError: (Object error) {
        AppLog.d('LocationService: position stream error: $error');
      },
    );
  }

  Future<void> stopTracking() async {
    _tracking = false;
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

  Future<CurrentLocation?> fetchCurrentLocation({bool highAccuracy = true}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy:
              highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 12),
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

  Future<void> _emitCurrentLocation({bool highAccuracy = false}) async {
    if (!_tracking) {
      return;
    }

    try {
      final location = await fetchCurrentLocation(highAccuracy: highAccuracy);
      if (location != null) {
        _emitLocation(location);
      }
    } on LocationServiceDisabledException {
      rethrow;
    } on PermissionDeniedException {
      rethrow;
    }
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
