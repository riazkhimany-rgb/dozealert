import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/location_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/activity_recognition_service.dart';
import '../../services/app_permissions_service.dart';
import '../../services/background_monitor_service.dart';
import '../../utils/trip_ux_copy.dart';
import '../../widgets/settings_section_tile.dart';
import 'permissions_settings_screen.dart';

class LocationSettingsScreen extends StatelessWidget {
  const LocationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accuracy = context.select<LocationProvider, String>(
      (provider) {
        final location = provider.currentLocation;
        return location == null
            ? 'Unknown'
            : '${location.accuracy.toStringAsFixed(0)} m';
      },
    );
    final diagnostics = context.select<LocationProvider, BackgroundMonitorDiagnostics>(
      (provider) => provider.backgroundDiagnostics,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Permissions'),
          SettingsNavTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Location and notifications',
            subtitle: 'Fix GPS, notifications, and battery access',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PermissionsSettingsScreen(),
                ),
              );
            },
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 24),
            const SettingsSectionHeader(title: 'Activity detection'),
            const _ActivityRecognitionToggle(),
          ],
          const SizedBox(height: 24),
          const SettingsSectionHeader(title: 'Location Accuracy'),
          ListTile(
            leading: Icon(Icons.gps_fixed, color: colorScheme.primary),
            title: const Text('Current accuracy'),
            trailing: Text(
              accuracy,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (Platform.isAndroid) ...[
            const Divider(height: 32),
            const SettingsSectionHeader(title: 'Battery Optimization'),
            ListTile(
              leading: Icon(Icons.battery_saver_outlined, color: colorScheme.primary),
              title: const Text('Battery optimization'),
              subtitle: Text(
                'You may be prompted to disable battery restrictions when '
                'starting a trip.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const Divider(height: 32),
            const SettingsSectionHeader(title: 'Background trip'),
            SwitchListTile(
              secondary: Icon(Icons.sensors, color: colorScheme.primary),
              title: const Text(TripUxCopy.backgroundTripActive),
              subtitle: Text(
                diagnostics.backgroundMonitoringEnabled
                    ? TripUxCopy.foregroundServiceRunning
                    : TripUxCopy.startTripFromHomeHint,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              value: diagnostics.backgroundMonitoringEnabled,
              onChanged: null,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRecognitionToggle extends StatelessWidget {
  const _ActivityRecognitionToggle();

  Future<void> _handleChanged(BuildContext context, bool enabled) async {
    final settings = context.read<SettingsProvider>();
    final permissions = context.read<AppPermissionsService>();
    final location = context.read<LocationProvider>();
    final activity = context.read<ActivityRecognitionService>();

    if (enabled) {
      await settings.setActivityRecognitionEnabled(true);
      final granted = await permissions.requestActivityRecognition();
      if (!context.mounted) {
        return;
      }
      if (!granted) {
        await settings.setActivityRecognitionEnabled(false);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(TripUxCopy.activityRecognitionPermissionDenied),
          ),
        );
        return;
      }
      await location.syncActivityRecognitionFromSettings();
      return;
    }

    await settings.setActivityRecognitionEnabled(false);
    await activity.stopListening();
    await location.syncActivityRecognitionFromSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = context.select<SettingsProvider, bool>(
      (provider) => provider.activityRecognitionEnabled,
    );

    return SwitchListTile(
      secondary: Icon(Icons.directions_walk_outlined, color: colorScheme.primary),
      title: const Text(TripUxCopy.activityRecognitionSettingTitle),
      subtitle: Text(
        enabled
            ? TripUxCopy.activityRecognitionEnabledSubtitle
            : TripUxCopy.activityRecognitionDisabledSubtitle,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      value: enabled,
      onChanged: (value) => unawaited(_handleChanged(context, value)),
    );
  }
}
