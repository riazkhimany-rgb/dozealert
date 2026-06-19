import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/current_location.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

class LocationService {
  static const _updateInterval = Duration(seconds: 10);

  final StreamController<CurrentLocation> _controller =
      StreamController<CurrentLocation>.broadcast();

  Timer? _updateTimer;
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

  Future<void> startTracking() async {
    if (_tracking) {
      return;
    }

    _tracking = true;
    await _emitCurrentLocation();

    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (_) {
      unawaited(_emitCurrentLocation());
    });
  }

  Future<void> stopTracking() async {
    _tracking = false;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _emitCurrentLocation() async {
    if (!_tracking) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!_tracking || _controller.isClosed) {
        return;
      }

      _controller.add(
        CurrentLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
      );
    } on LocationServiceDisabledException {
      rethrow;
    } on PermissionDeniedException {
      rethrow;
    }
  }

  void dispose() {
    unawaited(stopTracking());
    unawaited(_controller.close());
  }
}
