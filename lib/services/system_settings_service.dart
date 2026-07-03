import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_log.dart';

/// Opens native OS settings screens that Flutter cannot reach directly.
class SystemSettingsService {
  static const _channel = MethodChannel('app.dozealert/system_volume');

  /// Opens the system Text-to-speech settings (Android only) so the user can
  /// change the spoken-alert voice or engine. Returns true if a settings screen
  /// was launched.
  Future<bool> openTtsSettings() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final launched = await _channel.invokeMethod<bool>('openTtsSettings');
      return launched ?? false;
    } catch (error, stackTrace) {
      AppLog.d('SystemSettingsService: failed to open TTS settings: $error');
      AppLog.d('$stackTrace');
      return false;
    }
  }
}
