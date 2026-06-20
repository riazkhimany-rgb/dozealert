import 'dart:io';

import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../utils/app_log.dart';

/// Temporarily adjusts device media volume for approach alerts.
class SystemVolumeService {
  static const _channel = MethodChannel('app.dozealert/system_volume');

  double? _savedVolume;
  bool _overrideActive = false;

  Future<void> applyApproachAlertVolume({required double targetVolume}) async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      if (!_overrideActive) {
        final current = await _channel.invokeMethod<double>('getVolume');
        _savedVolume = current ?? 0.0;
        _overrideActive = true;
      }

      await _channel.invokeMethod<void>(
        'setVolume',
        {'volume': AppSettings.clampApproachSystemVolume(targetVolume)},
      );
    } catch (error, stackTrace) {
      AppLog.d('SystemVolumeService: failed to apply alert volume: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> restoreSavedVolume() async {
    if (!_overrideActive || !Platform.isAndroid) {
      return;
    }

    final saved = _savedVolume;
    _savedVolume = null;
    _overrideActive = false;

    if (saved == null) {
      return;
    }

    try {
      await _channel.invokeMethod<void>(
        'setVolume',
        {'volume': saved.clamp(0.0, 1.0)},
      );
    } catch (error, stackTrace) {
      AppLog.d('SystemVolumeService: failed to restore volume: $error');
      AppLog.d('$stackTrace');
    }
  }
}
