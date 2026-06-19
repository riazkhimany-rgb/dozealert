import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/location_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/background_monitor_service.dart';
import '../../widgets/settings_section_tile.dart';

class DeveloperToolsScreen extends StatelessWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diagnostics = context.select<LocationProvider, BackgroundMonitorDiagnostics>(
      (provider) => provider.backgroundDiagnostics,
    );
    final destinationName = context.select<MonitoringProvider, String?>(
      (provider) => provider.selectedDestination?.name,
    );
    final location = context.select<LocationProvider, String>(
      (provider) {
        final current = provider.currentLocation;
        if (current == null) {
          return '—';
        }
        return '${current.latitude.toStringAsFixed(4)}, '
            '${current.longitude.toStringAsFixed(4)}';
      },
    );
    final testModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.testModeEnabled,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Diagnostics'),
          _InfoTile(
            title: 'Background monitoring',
            value: diagnostics.backgroundMonitoringEnabled ? 'Yes' : 'No',
          ),
          _InfoTile(
            title: 'Foreground service',
            value: diagnostics.foregroundServiceRunning ? 'Yes' : 'No',
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Current GPS'),
          ListTile(
            leading: Icon(Icons.my_location, color: colorScheme.primary),
            title: const Text('Coordinates'),
            trailing: Text(
              location,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Trip History'),
          ListTile(
            leading: Icon(Icons.history, color: colorScheme.primary),
            title: const Text('Trip History'),
            subtitle: Text(
              destinationName == null
                  ? 'No active destination.'
                  : 'Current: $destinationName',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Logs'),
          ListTile(
            leading: Icon(Icons.article_outlined, color: colorScheme.primary),
            title: const Text('Logs'),
            subtitle: Text(
              'View debug output in your IDE or adb logcat.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Debug Info'),
          _InfoTile(title: 'Test mode', value: testModeEnabled ? 'On' : 'Off'),
          _InfoTile(title: 'Destination', value: destinationName ?? 'None'),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Developer Tools'),
          SwitchListTile(
            secondary: Icon(Icons.bug_report_outlined, color: colorScheme.primary),
            title: const Text('Enable Test Mode'),
            subtitle: Text(
              'Simulate arrival when distance is 5 km or less.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: testModeEnabled,
            onChanged: context.read<SettingsProvider>().setTestModeEnabled,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
