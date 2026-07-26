import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_log.dart';

/// Native iOS helpers for locked-phone wake reliability (geofence, BG task, audio).
///
/// No-op on non-iOS platforms.
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

  Future<void> armAudioSession() async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('armAudioSession');
    } catch (error, stackTrace) {
      AppLog.d('IosLockedReliability: armAudioSession failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> beginBackgroundTask({String name = 'dozealert.alarm'}) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('beginBackgroundTask', {'name': name});
    } catch (error, stackTrace) {
      AppLog.d('IosLockedReliability: beginBackgroundTask failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> endBackgroundTask() async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('endBackgroundTask');
    } catch (error, stackTrace) {
      AppLog.d('IosLockedReliability: endBackgroundTask failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  /// Registers circular regions around the destination (approach + inner ring).
  Future<void> startGeofences({
    required double latitude,
    required double longitude,
    required double approachRadiusMeters,
    required double destinationRadiusMeters,
  }) async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('startGeofences', {
        'latitude': latitude,
        'longitude': longitude,
        'approachRadiusMeters': approachRadiusMeters.clamp(100.0, 100000.0),
        'destinationRadiusMeters':
            destinationRadiusMeters.clamp(100.0, 100000.0),
      });
    } catch (error, stackTrace) {
      AppLog.d('IosLockedReliability: startGeofences failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> stopGeofences() async {
    if (!Platform.isIOS) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('stopGeofences');
    } catch (error, stackTrace) {
      AppLog.d('IosLockedReliability: stopGeofences failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> dispose() async {
    await stopGeofences();
    await endBackgroundTask();
    await _regionEnteredController.close();
  }
}
