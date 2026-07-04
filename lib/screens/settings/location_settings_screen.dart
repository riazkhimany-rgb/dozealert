import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/location_provider.dart';
import '../../services/background_monitor_service.dart';
import '../../widgets/settings_section_tile.dart';
import '../../widgets/wake_radius_dropdown.dart';

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
          const SettingsSectionHeader(title: 'Wake Radius'),
          const WakeRadiusDropdown(),
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
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Battery Optimization'),
          ListTile(
            leading: Icon(Icons.battery_saver_outlined, color: colorScheme.primary),
            title: const Text('Battery optimization'),
            subtitle: Text(
              'You may be prompted to disable battery restrictions when '
              'starting monitoring.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Background Monitoring'),
          SwitchListTile(
            secondary: Icon(Icons.sensors, color: colorScheme.primary),
            title: const Text('Background monitoring active'),
            subtitle: Text(
              diagnostics.backgroundMonitoringEnabled
                  ? 'Foreground service is running.'
                  : 'Start monitoring from Home to enable.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: diagnostics.backgroundMonitoringEnabled,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}
