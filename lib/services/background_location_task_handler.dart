import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/background_transit_pattern.dart';
import '../models/monitoring_state.dart';
import '../services/background_transit_evaluator.dart';
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
  final BackgroundTransitEvaluator _transitEvaluator =
      BackgroundTransitEvaluator();

  String _destinationName = 'Destination';
  double? _destinationLatitude;
  double? _destinationLongitude;
  int _radiusMeters = 1000;
  bool _testModeEnabled = false;
  bool _transitModeEnabled = false;
  bool _transitOnRoute = false;
  int _transitStopsRemaining = -1;
  int _transitWakeStopCount = 0;
  bool _transitDirectionLocked = false;
  bool _transitHasTripConcern = false;
  String _transitTripConcernType = '';
  bool _arrivalTriggered = false;
  int? _monitoringStartedAtMs;
  BackgroundTransitPattern? _transitPattern;
  String _alarmHeadline = 'Wake up!';
  String _alarmBody = '';
  String _alarmStopName = '';
  String _alarmSubline = '';
  String _lineLabel = '';
  int _lastWearSyncAtMs = 0;
  int _lastWearStopsRemaining = -999;

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
    _transitOnRoute =
        prefs.getBool(MonitoringStorageService.transitOnRouteKey) ?? false;
    _transitStopsRemaining =
        prefs.getInt(MonitoringStorageService.transitStopsRemainingKey) ?? -1;
    _transitWakeStopCount =
        prefs.getInt(MonitoringStorageService.transitWakeStopCountKey) ?? 0;
    _transitDirectionLocked =
        prefs.getBool(MonitoringStorageService.transitDirectionLockedKey) ??
            false;
    _transitHasTripConcern =
        prefs.getBool(MonitoringStorageService.transitHasTripConcernKey) ??
            false;
    _arrivalTriggered =
        prefs.getBool(MonitoringStorageService.arrivalTriggeredKey) ?? false;
    _monitoringStartedAtMs =
        prefs.getInt(MonitoringStorageService.monitoringStartedAtKey);
    _alarmHeadline =
        prefs.getString(MonitoringStorageService.transitAlarmHeadlineKey) ??
            'Wake up!';
    _alarmBody =
        prefs.getString(MonitoringStorageService.transitAlarmBodyKey) ?? '';
    _alarmStopName =
        prefs.getString(MonitoringStorageService.transitAlarmStopNameKey) ?? '';
    _alarmSubline =
        prefs.getString(MonitoringStorageService.transitAlarmSublineKey) ?? '';
    _lineLabel =
        prefs.getString(MonitoringStorageService.transitLineLabelKey) ?? '';

    final patternRaw =
        prefs.getString(MonitoringStorageService.transitPatternSnapshotKey);
    _transitPattern = BackgroundTransitPattern.fromJsonString(patternRaw);
    final stabilizedSequence =
        prefs.getInt(MonitoringStorageService.transitStabilizedStopSequenceKey);
    if (_transitPattern != null &&
        stabilizedSequence != null &&
        stabilizedSequence > 0) {
      _transitPattern = _transitPattern!.copyWith(
        stabilizedStopSequence: stabilizedSequence,
      );
    }
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
    final distanceKm = distanceMeters / 1000;

    if (_transitModeEnabled) {
      await _evaluateTransitPosition(
        position: position,
        distanceKm: distanceKm,
      );
    }

    await _refreshNotification(
      distanceKm: distanceKm,
      stopsRemaining: _transitOnRoute ? _transitStopsRemaining : null,
    );

    if (_arrivalTriggered) {
      return;
    }

    if (_transitModeEnabled && _transitOnRoute) {
      if (_shouldTriggerTransitWake()) {
        await _triggerArrival(transitWake: true);
      }
      return;
    }

    final thresholdMeters = _testModeEnabled
        ? _testModeArrivalThresholdMeters
        : _radiusMeters.toDouble();

    if (distanceMeters > thresholdMeters) {
      return;
    }

    await _triggerArrival();
  }

  Future<void> _evaluateTransitPosition({
    required Position position,
    required double distanceKm,
  }) async {
    await _reloadTransitPatternFromPrefs();

    final pattern = _transitPattern;
    if (pattern == null || !pattern.isValid) {
      return;
    }

    final evaluation = _transitEvaluator.evaluate(
      pattern: pattern,
      latitude: position.latitude,
      longitude: position.longitude,
      headingDegrees: position.heading,
      speedMps: position.speed,
    );
    if (evaluation == null) {
      return;
    }

    if (!evaluation.onRoute) {
      _transitOnRoute = false;
      return;
    }

    _transitOnRoute = true;
    _transitStopsRemaining = evaluation.stopsRemaining;
    _transitDirectionLocked = evaluation.directionLocked;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MonitoringStorageService.transitOnRouteKey, true);
    await prefs.setInt(
      MonitoringStorageService.transitStopsRemainingKey,
      evaluation.stopsRemaining,
    );
    await prefs.setBool(
      MonitoringStorageService.transitDirectionLockedKey,
      evaluation.directionLocked,
    );
    await prefs.setInt(
      MonitoringStorageService.transitStabilizedStopSequenceKey,
      evaluation.stabilizedStopSequence,
    );

    _transitPattern = pattern.copyWith(
      stabilizedStopSequence: evaluation.stabilizedStopSequence,
    );

    _maybePushWearSync(
      distanceKm: distanceKm,
      stopsRemaining: evaluation.stopsRemaining,
    );
  }

  Future<void> _reloadTransitPatternFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _transitWakeStopCount =
        prefs.getInt(MonitoringStorageService.transitWakeStopCountKey) ?? 0;
    _transitHasTripConcern =
        prefs.getBool(MonitoringStorageService.transitHasTripConcernKey) ??
            false;
    _transitTripConcernType =
        prefs.getString(MonitoringStorageService.transitTripConcernTypeKey) ??
            '';
    _transitDirectionLocked =
        prefs.getBool(MonitoringStorageService.transitDirectionLockedKey) ??
            false;
    _alarmHeadline =
        prefs.getString(MonitoringStorageService.transitAlarmHeadlineKey) ??
            'Wake up!';
    _alarmBody =
        prefs.getString(MonitoringStorageService.transitAlarmBodyKey) ?? '';
    _alarmStopName =
        prefs.getString(MonitoringStorageService.transitAlarmStopNameKey) ?? '';
    _alarmSubline =
        prefs.getString(MonitoringStorageService.transitAlarmSublineKey) ?? '';
    _lineLabel =
        prefs.getString(MonitoringStorageService.transitLineLabelKey) ?? '';

    final patternRaw =
        prefs.getString(MonitoringStorageService.transitPatternSnapshotKey);
    var pattern = BackgroundTransitPattern.fromJsonString(patternRaw);
    final stabilizedSequence =
        prefs.getInt(MonitoringStorageService.transitStabilizedStopSequenceKey);
    if (pattern != null &&
        stabilizedSequence != null &&
        stabilizedSequence > 0) {
      pattern = pattern.copyWith(stabilizedStopSequence: stabilizedSequence);
    }
    _transitPattern = pattern;
  }

  void _maybePushWearSync({
    required double distanceKm,
    required int stopsRemaining,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final stopsChanged = stopsRemaining != _lastWearStopsRemaining;
    final intervalElapsed = now - _lastWearSyncAtMs >= 15000;
    if (!stopsChanged && !intervalElapsed) {
      return;
    }

    _lastWearSyncAtMs = now;
    _lastWearStopsRemaining = stopsRemaining;

    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'type': 'wear_sync',
      'state': MonitoringState.monitoring.name,
      'destinationName': _destinationName,
      'distanceKm': distanceKm,
      'distanceReady': true,
      'stopsRemaining': stopsRemaining,
      'transitActive': _transitOnRoute,
      'lineLabel': _lineLabel,
      // Propagate concern type so the watch shows the correct message
      // ("Wrong direction?" / "Route uncertain") while the phone is backgrounded.
      'tripConcern': _transitHasTripConcern ? _transitTripConcernType : '',
      'alarmActive': false,
      'hasDestination': true,
      'alarmStopName': _alarmStopName,
      'alarmHeadline': _alarmHeadline,
      'alarmSubline': _alarmSubline,
    });
  }

  bool _shouldTriggerTransitWake() {
    // A trip concern (e.g. a shaky "wrong direction" guess) must not suppress
    // the wake here either — mirror the foreground rule so the alarm always
    // fires once the rider is within the wake threshold.
    if (!_transitDirectionLocked) {
      return false;
    }
    if (_transitStopsRemaining < 0) {
      return false;
    }
    return _transitStopsRemaining <= _transitWakeStopCount;
  }

  Future<void> _triggerArrival({bool transitWake = false}) async {
    _arrivalTriggered = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(MonitoringStorageService.arrivalTriggeredKey, true);
    await prefs.setInt(
      MonitoringStorageService.stateKey,
      MonitoringState.arrived.index,
    );

    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'type': transitWake ? 'transit_arrived' : 'arrived',
    });

    if (transitWake) {
      FlutterForegroundTask.sendDataToMain(<String, Object>{
        'type': 'wear_sync',
        'state': MonitoringState.arrived.name,
        'destinationName': _destinationName,
        'distanceKm': 0.0,
        'distanceReady': true,
        'stopsRemaining': _transitStopsRemaining,
        'transitActive': true,
        'lineLabel': _lineLabel,
        'alarmActive': true,
        'hasDestination': true,
        'alarmStopName': _alarmStopName,
        'alarmHeadline': _alarmHeadline,
        'alarmSubline': _alarmSubline,
      });
    }

    final notificationTitle =
        transitWake && _alarmHeadline.isNotEmpty ? _alarmHeadline : 'DozeAlert';
    final notificationText = transitWake
        ? (_alarmBody.isNotEmpty
            ? _alarmBody
            : 'Stop alert — $_destinationName is coming up.')
        : 'Destination reached — $_destinationName is nearby.';

    await FlutterForegroundTask.updateService(
      notificationTitle: notificationTitle,
      notificationText: notificationText,
    );
  }

  Future<void> _refreshNotification({
    double? distanceKm,
    int? stopsRemaining,
  }) async {
    String distanceLabel;
    if (stopsRemaining != null && stopsRemaining >= 0) {
      distanceLabel = stopsRemaining == 0
          ? 'At your stop'
          : stopsRemaining == 1
              ? '1 stop remaining'
              : '$stopsRemaining stops remaining';
    } else {
      distanceLabel = distanceKm != null
          ? '${distanceKm.toStringAsFixed(1)} km remaining'
          : 'Waiting for location...';
    }

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
