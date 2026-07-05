import 'dart:async';
import 'dart:io';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/settings_service.dart';
import '../utils/app_log.dart';

/// Detects rider motion so GPS priority and stop rules can adapt.
class ActivityRecognitionService {
  ActivityRecognitionService(this._settingsService);

  final SettingsService _settingsService;

  final StreamController<bool> _vehicleActivityController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _onFootActivityController =
      StreamController<bool>.broadcast();

  StreamSubscription<ActivityEvent>? _activitySubscription;
  bool _inVehicle = false;
  bool _onFoot = false;
  bool _listening = false;

  Stream<bool> get vehicleActivityStream => _vehicleActivityController.stream;

  Stream<bool> get onFootActivityStream => _onFootActivityController.stream;

  bool get inVehicle => _inVehicle;

  bool get onFoot => _onFoot;

  bool get isFeatureEnabled =>
      Platform.isAndroid &&
      _settingsService.settings.activityRecognitionEnabled;

  /// Null when activity recognition is not running or has no confident signal.
  bool? get activityInVehicleHint {
    if (!isFeatureEnabled || !_listening) {
      return null;
    }
    if (_inVehicle) {
      return true;
    }
    if (_onFoot) {
      return false;
    }
    return null;
  }

  bool? get activityOnFootHint {
    if (!isFeatureEnabled || !_listening) {
      return null;
    }
    if (_onFoot) {
      return true;
    }
    if (_inVehicle) {
      return false;
    }
    return null;
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      return true;
    }

    final requested = await Permission.activityRecognition.request();
    return requested.isGranted;
  }

  Future<void> startListening() async {
    if (!isFeatureEnabled || _listening || !Platform.isAndroid) {
      return;
    }

    final granted = await requestPermission();
    if (!granted) {
      AppLog.d('ActivityRecognitionService: permission denied');
      return;
    }

    final available = await ActivityRecognition().isAvailable();
    if (!available) {
      AppLog.d('ActivityRecognitionService: not available on device');
      return;
    }

    _listening = true;
    _activitySubscription = ActivityRecognition()
        .activityStream(runForegroundService: false)
        .listen(
      (event) => _applyActivity(event),
      onError: (Object error) {
        AppLog.d('ActivityRecognitionService: stream error: $error');
      },
    );
  }

  Future<void> stopListening() async {
    if (!_listening) {
      return;
    }

    _listening = false;
    _setMotion(inVehicle: false, onFoot: false);
    await _activitySubscription?.cancel();
    _activitySubscription = null;
    if (Platform.isAndroid) {
      await ActivityRecognition().stopActivityUpdates();
    }
  }

  void _applyActivity(ActivityEvent event) {
    if (!isFeatureEnabled) {
      return;
    }

    if (event.confidence < 50) {
      return;
    }

    final vehicle = event.type == ActivityType.inVehicle ||
        event.type == ActivityType.onBicycle;
    if (vehicle) {
      _setMotion(inVehicle: true, onFoot: false);
      return;
    }

    final onFoot = event.type == ActivityType.onFoot ||
        event.type == ActivityType.walking ||
        event.type == ActivityType.still;
    if (onFoot) {
      _setMotion(inVehicle: false, onFoot: true);
    }
  }

  void _setMotion({required bool inVehicle, required bool onFoot}) {
    if (inVehicle == _inVehicle && onFoot == _onFoot) {
      return;
    }

    _inVehicle = inVehicle;
    _onFoot = onFoot;
    _vehicleActivityController.add(inVehicle);
    _onFootActivityController.add(onFoot);
  }

  void dispose() {
    unawaited(stopListening());
    unawaited(_vehicleActivityController.close());
    unawaited(_onFootActivityController.close());
  }
}
