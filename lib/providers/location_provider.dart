import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/current_location.dart';
import '../providers/monitoring_provider.dart';
import '../services/location_service.dart';

enum LocationStartResult {
  success,
  noDestination,
  permissionDenied,
  permissionPermanentlyDenied,
  locationServiceDisabled,
}

class LocationProvider extends ChangeNotifier {
  LocationProvider(this._locationService, this._monitoringProvider) {
    _locationSubscription = _locationService.locationStream.listen(
      _onLocationUpdate,
    );
    _monitoringProvider.addListener(_onMonitoringChanged);
  }

  final LocationService _locationService;
  final MonitoringProvider _monitoringProvider;

  StreamSubscription<CurrentLocation>? _locationSubscription;

  CurrentLocation? _currentLocation;
  double _distanceRemainingMeters = 0;
  double _distanceRemainingKm = 0;
  bool _trackingEnabled = false;

  CurrentLocation? get currentLocation => _currentLocation;
  double get distanceRemainingMeters => _distanceRemainingMeters;
  double get distanceRemainingKm => _distanceRemainingKm;
  bool get trackingEnabled => _trackingEnabled;

  bool get hasDestination => _monitoringProvider.selectedDestination != null;

  Future<LocationStartResult> startTracking() async {
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

    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStartResult.locationServiceDisabled;
    }

    try {
      await _locationService.startTracking();
    } on LocationServiceDisabledException {
      return LocationStartResult.locationServiceDisabled;
    } on PermissionDeniedException {
      return LocationStartResult.permissionDenied;
    }

    _trackingEnabled = true;
    _monitoringProvider.startMonitoring();
    notifyListeners();
    return LocationStartResult.success;
  }

  Future<void> stopTracking() async {
    if (!_trackingEnabled) {
      return;
    }

    await _locationService.stopTracking();
    _trackingEnabled = false;
    _monitoringProvider.stopMonitoring();
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

  void _onLocationUpdate(CurrentLocation location) {
    _currentLocation = location;
    updateDistance();
    notifyListeners();
  }

  void _onMonitoringChanged() {
    updateDistance();

    if (_monitoringProvider.selectedDestination == null && _trackingEnabled) {
      unawaited(stopTracking());
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _monitoringProvider.removeListener(_onMonitoringChanged);
    super.dispose();
  }
}
