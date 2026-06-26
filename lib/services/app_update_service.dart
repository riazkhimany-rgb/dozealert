import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/remote_app_version.dart';
import '../utils/app_branding.dart';
import '../utils/app_log.dart';
import '../utils/external_link_launcher.dart';

/// Checks for app updates via Google Play In-App Updates, with a website
/// version check fallback for sideloaded APK installs.
class AppUpdateService {
  AppUpdateService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _dismissedBuildKey = 'app_update_dismissed_build';
  static const _highPriorityThreshold = 4;

  final http.Client _http;

  /// Play Console update priority at or above this uses an immediate update
  /// when allowed.
  static bool shouldUseImmediateUpdate(AppUpdateInfo info) {
    return shouldUseImmediateUpdateFor(
      immediateUpdateAllowed: info.immediateUpdateAllowed,
      updatePriority: info.updatePriority,
    );
  }

  static bool shouldUseImmediateUpdateFor({
    required bool immediateUpdateAllowed,
    required int updatePriority,
  }) {
    return immediateUpdateAllowed && updatePriority >= _highPriorityThreshold;
  }

  /// Returns `true` when [remote] is newer than [currentBuild].
  static bool hasWebsiteUpdate({
    required RemoteAppVersion? remote,
    required int currentBuild,
    required int? dismissedBuild,
  }) {
    if (remote == null || !remote.isNewerThan(currentBuild)) {
      return false;
    }
    return dismissedBuild == null || remote.build != dismissedBuild;
  }

  Future<void> checkAndPromptIfNeeded(BuildContext context) async {
    if (!Platform.isAndroid) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    final playHandled = await _tryPlayStoreUpdate(context);
    if (playHandled) {
      return;
    }

    final remote = await _fetchRemoteVersion();
    final prefs = await SharedPreferences.getInstance();
    final dismissedBuild = prefs.getInt(_dismissedBuildKey);

    if (!hasWebsiteUpdate(
      remote: remote,
      currentBuild: currentBuild,
      dismissedBuild: dismissedBuild,
    )) {
      return;
    }

    if (!context.mounted || remote == null) {
      return;
    }

    await _showWebsiteUpdateDialog(
      context,
      remote: remote,
      currentVersion: packageInfo.version,
    );
  }

  Future<bool> _tryPlayStoreUpdate(BuildContext context) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return true;
      }

      if (!context.mounted) {
        return true;
      }

      if (shouldUseImmediateUpdate(info)) {
        await InAppUpdate.performImmediateUpdate();
        return true;
      }

      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (!context.mounted) {
          return true;
        }

        if (result == AppUpdateResult.success) {
          _showFlexibleUpdateSnackBar(context);
        }
        return true;
      }

      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
      return true;
    } catch (error, stackTrace) {
      AppLog.d('AppUpdateService: Play in-app update unavailable: $error');
      AppLog.d('$stackTrace');
      return false;
    }
  }

  void _showFlexibleUpdateSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded. Restart to install.'),
        action: SnackBarAction(
          label: 'Restart',
          onPressed: () {
            unawaited(InAppUpdate.completeFlexibleUpdate());
          },
        ),
      ),
    );
  }

  Future<RemoteAppVersion?> _fetchRemoteVersion() async {
    try {
      final response = await _http
          .get(Uri.parse(AppBranding.appVersionJsonUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return RemoteAppVersion.fromJson(decoded);
    } catch (error, stackTrace) {
      AppLog.d('AppUpdateService: website version check failed: $error');
      AppLog.d('$stackTrace');
      return null;
    }
  }

  Future<void> _showWebsiteUpdateDialog(
    BuildContext context, {
    required RemoteAppVersion remote,
    required String currentVersion,
  }) async {
    final updateLabel = remote.displayLabel;
    final shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update available'),
          content: Text(
            'A new version of ${AppBranding.appName} is available '
            '($updateLabel). You are on $currentVersion.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Download update'),
            ),
          ],
        );
      },
    );

    if (shouldUpdate != true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dismissedBuildKey, remote.build);
      return;
    }

    if (!context.mounted) {
      return;
    }

    await ExternalLinkLauncher.openOrSnackBar(
      context,
      AppBranding.apkDownloadUrl,
    );
  }
}
