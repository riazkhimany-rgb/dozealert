import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_log.dart';

/// Opens this app's page in the iOS/Android Settings app when possible.
///
/// On newer iOS versions, the public Settings URL sometimes lands on the
/// root Settings list (Apps is nested). We try bundle-id deep links first,
/// then fall back to the platform Settings API.
Future<void> openDozeAlertAppSettings() async {
  if (Platform.isIOS) {
    const candidates = <String>[
      'App-prefs:app.dozealert',
      'App-Prefs:app.dozealert',
      'app-settings:',
    ];
    for (final raw in candidates) {
      try {
        final uri = Uri.parse(raw);
        if (await launchUrl(uri)) {
          return;
        }
      } catch (error) {
        AppLog.d('openDozeAlertAppSettings failed for $raw: $error');
      }
    }
  }

  await openAppSettings();
}
