import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_permission_snapshot.dart';
import '../services/app_permissions_service.dart';
import '../utils/permission_setup_steps.dart';
import 'permission_step_confirm_dialog.dart';

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
  bool _setupStarted = false;
  bool _showAllDetails = false;
  bool _autoFlowRunning = false;
  PermissionSetupStep? _activeStep;

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
      unawaited(_refresh().then((_) => _scheduleAutomaticFlow(resume: true)));
    }
  }

  bool _needsAutomaticFlow(AppPermissionSnapshot snapshot) {
    return _setupStarted && !snapshot.allRequiredForMonitoring;
  }

  Future<void> _scheduleAutomaticFlow({bool resume = false}) async {
    if (!mounted || _autoFlowRunning || !_setupStarted) {
      return;
    }

    final snapshot = _snapshot;
    if (snapshot == null || !_needsAutomaticFlow(snapshot)) {
      return;
    }

    if (!resume) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }

    await _runAutomaticFlow();
  }

  Future<void> _startSetup() async {
    setState(() => _setupStarted = true);
    await _runAutomaticFlow();
  }

  Future<void> _runAutomaticFlow() async {
    if (!mounted || _autoFlowRunning) {
      return;
    }

    final snapshot = _snapshot;
    if (snapshot == null || !_needsAutomaticFlow(snapshot)) {
      return;
    }

    setState(() => _autoFlowRunning = true);

    final permissions = context.read<AppPermissionsService>();
    await permissions.runAutomaticSetupFlow(
      onStep: (step) {
        if (!mounted) {
          return;
        }
        setState(() => _activeStep = step);
      },
      onBeforeStep: (step) async {
        if (!mounted) {
          return false;
        }
        return showPermissionStepConfirmDialog(context, step);
      },
    );
    await _refresh();

    if (mounted) {
      setState(() {
        _autoFlowRunning = false;
        _activeStep = null;
      });
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

  Future<void> _runStepAction(String itemId) async {
    final permissions = context.read<AppPermissionsService>();
    final step = setupStepForItemId(itemId);

    if (step != null) {
      final proceed = await showPermissionStepConfirmDialog(context, step);
      if (!proceed || !mounted) {
        return;
      }
      setState(() => _activeStep = step);
    }

    switch (itemId) {
      case 'gps':
        await permissions.openLocationSettings();
      case 'location_when_in_use':
        await permissions.requestLocationWhenInUse();
      case 'background_location':
        await permissions.requestBackgroundLocation();
      case 'notifications':
        await permissions.requestNotifications();
      case 'battery':
        await permissions.requestBatteryOptimization();
    }

    await _refresh();
    if (mounted) {
      setState(() => _activeStep = null);
    }
  }

  Future<void> _openAppSettingsForBackground() async {
    final proceed = await showPermissionStepConfirmDialog(
      context,
      PermissionSetupStep.backgroundLocation,
    );
    if (!proceed || !mounted) {
      return;
    }

    setState(() => _activeStep = PermissionSetupStep.backgroundLocation);
    await context.read<AppPermissionsService>().openAppSettingsPage();
    await _refresh();
    if (mounted) {
      setState(() => _activeStep = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final snapshot = _snapshot;

    if (_loading || snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final requiredComplete = snapshot.allRequiredForMonitoring;
    final stepProgress = completedRequiredSetupStepCount(snapshot);
    final stepTotal = requiredSetupStepCount();
    final nextItem = nextIncompleteSetupItem(snapshot);
    final showSuccess = _setupStarted && requiredComplete && !_autoFlowRunning;
    final inStepMode = _setupStarted && !_showAllDetails;
    final showRecovery = needsBackgroundLocationRecovery(snapshot);
    final showDetailedTiles = _setupStarted && _showAllDetails;

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
              ? 'Tap Start below. We will walk you through each permission '
                  'one at a time — read the short prompt before each Android '
                  'screen and choose the option shown in bold.'
              : 'Tap Start to grant location access before your first trip.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (_setupStarted) ...[
          const SizedBox(height: 16),
          Text(
            'Progress: $stepProgress of $stepTotal required steps complete',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (_autoFlowRunning) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _activeStep == PermissionSetupStep.backgroundLocation
                      ? 'Choose Allow all the time on the next screen…'
                      : _activeStep == PermissionSetupStep.batteryOptimization
                          ? 'Allow battery exemption on the next screen…'
                          : 'Follow the Android prompts…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showSuccess) ...[
          const SizedBox(height: 20),
          _SuccessCard(colorScheme: colorScheme),
        ],
        if (showRecovery) ...[
          const SizedBox(height: 16),
          _StepCallout(
            icon: Icons.warning_amber_rounded,
            title: 'Fix background location',
            body:
                'Location step 1 is granted, but step 2 is still missing. '
                'Open app settings, then Permissions → Location → '
                'Allow all the time.\n\n'
                'Do not leave it on "Only while using the app".',
            color: colorScheme.errorContainer,
            foreground: colorScheme.onErrorContainer,
            actionLabel: 'Open app settings',
            onAction: () => unawaited(_openAppSettingsForBackground()),
          ),
        ],
        const SizedBox(height: 20),
        PermissionStepProgressList(
          snapshot: snapshot,
          activeStep: _activeStep,
          dimIncomplete: !_setupStarted,
        ),
        const SizedBox(height: 16),
        if (!_setupStarted)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => unawaited(_startSetup()),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start permission setup'),
            ),
          )
        else if (_needsAutomaticFlow(snapshot) && !_autoFlowRunning)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => unawaited(_runAutomaticFlow()),
              icon: const Icon(Icons.refresh),
              label: const Text('Resume permission setup'),
            ),
          ),
        if (inStepMode && nextItem != null && !_autoFlowRunning) ...[
          const SizedBox(height: 16),
          _CurrentStepCard(
            item: nextItem,
            onAction: () => unawaited(_runStepAction(nextItem.id)),
            onOpenSettings: nextItem.id == 'background_location'
                ? () => unawaited(_openAppSettingsForBackground())
                : null,
          ),
        ],
        if (_setupStarted) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => setState(() => _showAllDetails = !_showAllDetails),
              child: Text(
                _showAllDetails
                    ? 'Hide all permission details'
                    : 'Show all permission details',
              ),
            ),
          ),
        ],
        if (showDetailedTiles) ...[
          const SizedBox(height: 8),
          ..._buildDetailedTiles(snapshot),
        ] else if (_setupStarted && !requiredComplete && inStepMode) ...[
          const SizedBox(height: 8),
          Text(
            'Still needed:\n${snapshot.missingRequiredLabels.map((item) => '• $item').join('\n')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildDetailedTiles(AppPermissionSnapshot snapshot) {
    final permissions = context.read<AppPermissionsService>();

    return [
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
        onAction: () => unawaited(_runStepAction('location_when_in_use')),
      ),
      if (Platform.isAndroid)
        _PermissionTile(
          complete: snapshot.backgroundLocationGranted,
          title: 'Location (step 2)',
          requiredSetting: 'Allow all the time',
          detail: 'On the Android permission screen, choose '
              '"Allow all the time". If you only see app settings, open '
              'Permissions → Location → Allow all the time.',
          actionLabel: 'Request background location',
          onAction: () => unawaited(_runStepAction('background_location')),
          secondaryActionLabel: 'Open app settings',
          onSecondaryAction: () => unawaited(_openAppSettingsForBackground()),
        ),
      if (Platform.isAndroid)
        _PermissionTile(
          complete: snapshot.notificationsGranted,
          title: 'Notifications',
          requiredSetting: 'Allowed',
          detail: 'Shows the ongoing trip monitoring notification while '
              'DozeAlert tracks your progress in the background.',
          actionLabel: 'Allow notifications',
          onAction: () => unawaited(_runStepAction('notifications')),
        ),
      if (Platform.isAndroid)
        _PermissionTile(
          complete: snapshot.batteryUnrestricted,
          title: 'Battery',
          requiredSetting: 'Unrestricted / not optimized',
          detail: 'Allow DozeAlert to ignore battery optimizations so '
              'monitoring and alarms stay reliable in the background.',
          actionLabel: 'Allow unrestricted battery',
          onAction: () => unawaited(_runStepAction('battery')),
        ),
    ];
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re ready!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Required permissions are set. Tap Continue to pick your transit '
              'agency, then set your first destination on Home.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentStepCard extends StatelessWidget {
  const _CurrentStepCard({
    required this.item,
    required this.onAction,
    this.onOpenSettings,
  });

  final PermissionSetupItem item;
  final VoidCallback onAction;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Up next: ${item.title}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.required
                  ? 'Set to: ${item.subtitle}'
                  : 'Recommended: ${item.subtitle}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onAction,
              child: const Text('Continue this step'),
            ),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onOpenSettings,
                child: const Text('Open app settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepCallout extends StatelessWidget {
  const _StepCallout({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.foreground,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color foreground;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foreground,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
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
  });

  final bool complete;
  final String title;
  final String requiredSetting;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

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
                        'Set to: $requiredSetting',
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
                  onPressed: complete ? null : onAction,
                  child: Text(complete ? 'Granted' : actionLabel),
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
