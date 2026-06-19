import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/location_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/background_monitor_service.dart';
import '../../utils/monitoring_format.dart';
import '../../widgets/settings_section_tile.dart';

class LocationSettingsScreen extends StatelessWidget {
  const LocationSettingsScreen({super.key});

  static const _radiusOptions = <int>[250, 500, 1000, 2000];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radiusMeters = context.select<MonitoringProvider, int>(
      (provider) => provider.radiusMeters,
    );
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
    final testModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.testModeEnabled,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Wake Radius'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Alert distance',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: radiusMeters,
                  items: _radiusOptions
                      .map(
                        (meters) => DropdownMenuItem<int>(
                          value: meters,
                          child: Text(MonitoringFormat.radiusLabel(meters)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<MonitoringProvider>().setRadius(value);
                    }
                  },
                ),
              ),
            ),
          ),
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
          SwitchListTile(
            secondary: Icon(Icons.bug_report_outlined, color: colorScheme.primary),
            title: const Text('Test Mode'),
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
