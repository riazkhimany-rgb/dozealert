import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_log.dart';

/// Native iOS helpers for locked-phone wake reliability.
///
/// Covers the three things Flutter cannot do on its own once the screen locks:
/// keeping the process alive, monitoring geofences, and firing the wake from
/// native code when the Dart isolate is suspended. No-op on other platforms.
class IosLockedReliabilityService {
  IosLockedReliabilityService() {
    if (Platform.isIOS) {
      _channel.setMethodCallHandler(_onNativeCall);
    }
  }

  static const _channel = MethodChannel('app.dozealert/ios_reliability');

  static const approachRegionId = 'dozealert.approach';
  static const destinationRegionId = 'dozealert.destination';

  final _regionEnteredController = StreamController<String>.broadcast();

  Stream<String> get regionEntered => _regionEnteredController.stream;

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (call.method == 'onRegionEntered') {
      final regionId = call.arguments as String? ?? '';
      if (regionId.isNotEmpty && !_regionEnteredController.isClosed) {
        _regionEnteredController.add(regionId);
      }
      return null;
    }
    throw PlatformException(
      code: 'unimplemented',
      message: 'Unknown method ${call.method}',
    );
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? arguments]) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (error, stackTrace) {
      AppLog.d('IosLockedReliability: $method failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> armAudioSession() => _invoke('armAudioSession');

  /// Starts the near-silent loop that keeps the app resident during a trip.
  Future<void> startKeepAlive() => _invoke('startKeepAlive');

  Future<void> stopKeepAlive() => _invoke('stopKeepAlive');

  Future<void> beginBackgroundTask({String name = 'dozealert.alarm'}) =>
      _invoke('beginBackgroundTask', {'name': name});

  Future<void> endBackgroundTask() => _invoke('endBackgroundTask');

  Future<void> stopNativeAlarm() => _invoke('stopNativeAlarm');

  /// Gives native code everything it needs to raise the wake without Dart.
  ///
  /// Pass [resetWake] only when a new trip starts; a periodic copy refresh must
  /// not clear a native wake that Dart has yet to adopt.
  ///
  /// [nativeWakeEnabled] should be false for wake-by-stops trips so a large
  /// distance geofence cannot start the tone one or two stops early.
  Future<void> setTripInfo({
    required String destinationName,
    required String alarmTitle,
    required String alarmBody,
    required bool criticalAlerts,
    bool resetWake = false,
    bool nativeWakeEnabled = true,
  }) {
    return _invoke('setTripInfo', {
      'destinationName': destinationName,
      'alarmTitle': alarmTitle,
      'alarmBody': alarmBody,
      'criticalAlerts': criticalAlerts,
      'resetWake': resetWake,
      'nativeWakeEnabled': nativeWakeEnabled,
    });
  }

  Future<void> clearTripInfo() => _invoke('clearTripInfo');

  /// True once if native code already fired the wake while Dart was suspended.
  Future<bool> consumeNativeWake() async {
    if (!Platform.isIOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('consumeNativeWake') ?? false;
    } catch (error, stackTrace) {
      AppLog.d('IosLockedReliability: consumeNativeWake failed: $error');
      AppLog.d('$stackTrace');
      return false;
    }
  }

  /// Registers circular regions around the destination (approach + inner ring).
  Future<void> startGeofences({
    required double latitude,
    required double longitude,
    required double approachRadiusMeters,
    required double destinationRadiusMeters,
  }) {
    return _invoke('startGeofences', {
      'latitude': latitude,
      'longitude': longitude,
      'approachRadiusMeters': approachRadiusMeters.clamp(100.0, 100000.0),
      'destinationRadiusMeters': destinationRadiusMeters.clamp(100.0, 100000.0),
    });
  }

  Future<void> stopGeofences() => _invoke('stopGeofences');

  Future<void> dispose() async {
    await stopGeofences();
    await stopKeepAlive();
    await clearTripInfo();
    await endBackgroundTask();
    await _regionEnteredController.close();
  }
}
