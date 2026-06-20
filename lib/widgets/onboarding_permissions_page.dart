import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_permission_snapshot.dart';
import '../services/app_permissions_service.dart';

class OnboardingPermissionsPage extends StatefulWidget {
  const OnboardingPermissionsPage({
    super.key,
    required this.onStatusChanged,
  });

  final ValueChanged<AppPermissionSnapshot> onStatusChanged;

  @override
  State<OnboardingPermissionsPage> createState() =>
      _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage>
    with WidgetsBindingObserver {
  AppPermissionSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final permissions = context.read<AppPermissionsService>();
    final next = await permissions.snapshot();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = next;
      _loading = false;
    });
    widget.onStatusChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final permissions = context.read<AppPermissionsService>();
    final snapshot = _snapshot;

    if (_loading || snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 64,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Permissions for trip monitoring',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          Platform.isAndroid
              ? 'DozeAlert needs the settings below before your first trip. '
                  'Tap each item to grant access or open the correct system screen.'
              : 'DozeAlert needs location access before your first trip. '
                  'Tap each item to grant access or open Settings.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _PermissionTile(
          complete: snapshot.locationServicesEnabled,
          title: 'Phone GPS',
          requiredSetting: 'Location services turned on',
          detail: 'Your phone\'s main Location / GPS switch must be on.',
          actionLabel: 'Open location settings',
          onAction: () async {
            await permissions.openLocationSettings();
            await _refresh();
          },
        ),
        _PermissionTile(
          complete: snapshot.locationWhenInUseGranted,
          title: Platform.isAndroid ? 'Location (step 1)' : 'Location',
          requiredSetting: Platform.isAndroid
              ? 'Allow only while using the app'
              : 'Allow While Using the App',
          detail: Platform.isAndroid
              ? 'Android will ask for this first. Choose '
                  '"While using the app" (not "Don\'t allow").'
              : 'Choose While Using the App when iOS prompts you.',
          actionLabel: 'Request location access',
          onAction: () async {
            await permissions.requestLocationWhenInUse();
            await _refresh();
          },
        ),
        if (Platform.isAndroid)
          _PermissionTile(
            complete: snapshot.backgroundLocationGranted,
            title: 'Location (step 2)',
            requiredSetting: 'Allow all the time',
            detail: 'Required so monitoring continues when the screen is off '
                'or you switch apps. Do not leave this on '
                '"Only while using the app".',
            actionLabel: 'Request background location',
            onAction: () async {
              await permissions.requestBackgroundLocation();
              await _refresh();
            },
            secondaryActionLabel: 'Open app settings',
            onSecondaryAction: () async {
              await permissions.openAppSettingsPage();
            },
          ),
        if (Platform.isAndroid)
          _PermissionTile(
            complete: snapshot.notificationsGranted,
            title: 'Notifications',
            requiredSetting: 'Allowed',
            detail: 'Shows the ongoing trip monitoring notification while '
                'DozeAlert tracks your progress in the background.',
            actionLabel: 'Allow notifications',
            onAction: () async {
              await permissions.requestNotifications();
              await _refresh();
            },
          ),
        if (Platform.isAndroid)
          _PermissionTile(
            complete: snapshot.batteryUnrestricted,
            title: 'Battery (recommended)',
            requiredSetting: 'Unrestricted / not optimized',
            detail: 'Helps alarms stay reliable on some phones. Choose '
                '"Unrestricted" or allow DozeAlert to ignore battery '
                'optimizations if prompted.',
            actionLabel: 'Open battery settings',
            onAction: () async {
              await permissions.openBatterySettings();
              await _refresh();
            },
            recommended: true,
          ),
        const SizedBox(height: 8),
        if (snapshot.allRequiredForMonitoring)
          Text(
            'Required permissions are set. You can continue setup.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Text(
            'Still needed:\n${snapshot.missingRequiredLabels.map((item) => '• $item').join('\n')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.complete,
    required this.title,
    required this.requiredSetting,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.recommended = false,
  });

  final bool complete;
  final String title;
  final String requiredSetting;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  complete ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: complete ? colorScheme.primary : colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommended
                            ? 'Recommended: $requiredSetting'
                            : 'Set to: $requiredSetting',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: complete
                              ? colorScheme.primary
                              : colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
                if (secondaryActionLabel != null && onSecondaryAction != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    child: Text(secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
