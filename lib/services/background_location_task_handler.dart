import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'monitoring_storage_service.dart';
import '../models/monitoring_state.dart';
import '../services/monitoring_storage_service.dart';

const _testModeArrivalThresholdMeters = 5000.0;
const _testModeKey = 'test_mode_enabled';
const _transitModeEnabledKey = 'transit_mode_enabled';
const _destinationNameKey = 'selected_destination_name';
const _destinationLatitudeKey = 'selected_destination_latitude';
const _destinationLongitudeKey = 'selected_destination_longitude';

@pragma('vm:entry-point')
void startBackgroundMonitoringCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(DozeAlertLocationTaskHandler());
}

class DozeAlertLocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  String _destinationName = 'Destination';
  double? _destinationLatitude;
  double? _destinationLongitude;
  int _radiusMeters = 1000;
  bool _testModeEnabled = false;
  bool _transitModeEnabled = false;
  bool _transitOnRoute = false;
  bool _arrivalTriggered = false;
  int? _monitoringStartedAtMs;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    final isActive =
        prefs.getBool(MonitoringStorageService.activeKey) ?? false;
    if (!isActive) {
      await FlutterForegroundTask.stopService();
      return;
    }

    await _loadSession();
    await _startLocationStream();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_refreshNotification());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'refresh_session') {
      unawaited(_loadSession());
    }
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _destinationName = prefs.getString(_destinationNameKey) ?? 'Destination';
    _destinationLatitude = prefs.getDouble(_destinationLatitudeKey);
    _destinationLongitude = prefs.getDouble(_destinationLongitudeKey);
    _radiusMeters = prefs.getInt(MonitoringStorageService.radiusKey) ?? 1000;
    _testModeEnabled = prefs.getBool(_testModeKey) ?? false;
    _transitModeEnabled = prefs.getBool(_transitModeEnabledKey) ?? true;
    _transitOnRoute = prefs.getBool(MonitoringStorageService.transitOnRouteKey) ?? false;
    _arrivalTriggered =
        prefs.getBool(MonitoringStorageService.arrivalTriggeredKey) ?? false;
    _monitoringStartedAtMs =
        prefs.getInt(MonitoringStorageService.monitoringStartedAtKey);
  }

  Future<void> _startLocationStream() async {
    await _positionSubscription?.cancel();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'DozeAlert',
        notificationText: 'Monitoring paused — GPS is disabled.',
      );
      return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: null,
      ),
    ).listen(
      _handlePosition,
      onError: (_) async {
        await FlutterForegroundTask.updateService(
          notificationTitle: 'DozeAlert',
          notificationText: 'Monitoring paused — location unavailable.',
        );
      },
    );
  }

  Future<void> _handlePosition(Position position) async {
    if (_isStalePosition(position)) {
      return;
    }

    if (position.accuracy > 150) {
      return;
    }

    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'type': 'location',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'timestamp': position.timestamp.millisecondsSinceEpoch,
    });

    final destinationLatitude = _destinationLatitude;
    final destinationLongitude = _destinationLongitude;
    if (destinationLatitude == null || destinationLongitude == null) {
      await _refreshNotification();
      return;
    }

    final distanceMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destinationLatitude,
      destinationLongitude,
    );

    await _refreshNotification(distanceKm: distanceMeters / 1000);

    if (_arrivalTriggered) {
      return;
    }

    // Transit mode: stop-based wake in foreground. Allow distance only as fallback.
    if (_transitModeEnabled && _transitOnRoute) {
      return;
    }

    final thresholdMeters = _testModeEnabled
        ? _testModeArrivalThresholdMeters
        : _radiusMeters.toDouble();

    if (distanceMeters > thresholdMeters) {
      return;
    }

    _arrivalTriggered = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MonitoringStorageService.arrivalTriggeredKey, true);
    await prefs.setInt(
      MonitoringStorageService.stateKey,
      MonitoringState.arrived.index,
    );

    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'type': 'arrived',
    });

    await FlutterForegroundTask.updateService(
      notificationTitle: 'DozeAlert',
      notificationText:
          'Destination reached — $_destinationName is nearby.',
    );
  }

  Future<void> _refreshNotification({double? distanceKm}) async {
    final distanceLabel = distanceKm != null
        ? '${distanceKm.toStringAsFixed(1)} km remaining'
        : 'Waiting for location...';

    await FlutterForegroundTask.updateService(
      notificationTitle: 'DozeAlert',
      notificationText:
          'Monitoring your trip...\n$_destinationName · $distanceLabel',
    );
  }

  bool _isStalePosition(Position position) {
    final startedAtMs = _monitoringStartedAtMs;
    if (startedAtMs == null) {
      return false;
    }

    return position.timestamp.millisecondsSinceEpoch < startedAtMs;
  }
}
