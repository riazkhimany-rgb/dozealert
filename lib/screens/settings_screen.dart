import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/train_mode_wake_setting.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/app_branding.dart';
import '../utils/location_format.dart';
import '../widgets/transit_preferences_section.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          RadioGroup<ThemeMode>(
            groupValue: themeProvider.themeMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
            child: Column(
              children: ThemeMode.values
                  .map(
                    (mode) => RadioListTile<ThemeMode>(
                      title: Text(_themeModeLabel(mode)),
                      value: mode,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 32),
          const TransitPreferencesSection(),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Train Mode',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Train Mode'),
            subtitle: Text(
              'Wake up based on stations remaining on your line.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: settingsProvider.trainModeEnabled,
            onChanged: settingsProvider.setTrainModeEnabled,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'Wake',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          RadioGroup<TrainModeWakeSetting>(
            groupValue: settingsProvider.trainModeWake,
            onChanged: (value) {
              if (!settingsProvider.trainModeEnabled || value == null) {
                return;
              }
              settingsProvider.setTrainModeWake(value);
            },
            child: Column(
              children: TrainModeWakeSetting.values
                  .map(
                    (wakeSetting) => RadioListTile<TrainModeWakeSetting>(
                      title: Text(wakeSetting.label),
                      value: wakeSetting,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Testing',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Test Mode'),
            subtitle: Text(
              'Simulate arrival when distance is 5 km or less.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: settingsProvider.testModeEnabled,
            onChanged: settingsProvider.setTestModeEnabled,
          ),
          const Divider(height: 32),
          const _DeveloperSettingsSection(),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'About',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: const AssetImage(
                'assets/branding/splash_logo.png',
              ),
            ),
            title: const Text('About DozeAlert'),
            subtitle: Text(
              AppBranding.tagline,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeveloperSettingsSection extends StatelessWidget {
  const _DeveloperSettingsSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diagnostics = context.select<LocationProvider, BackgroundMonitorDiagnostics>(
      (provider) => provider.backgroundDiagnostics,
    );
    final destinationName = context.select<MonitoringProvider, String?>(
      (provider) => provider.selectedDestination?.name,
    );
    final distanceKm = context.select<LocationProvider, double>(
      (provider) => provider.distanceRemainingKm,
    );
    final lastUpdated = context.select<LocationProvider, String>(
      (provider) {
        final timestamp = provider.currentLocation?.timestamp;
        return timestamp == null
            ? '—'
            : LocationFormat.lastUpdated(timestamp);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Developer Settings',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _DeveloperInfoTile(
          title: 'Background monitoring enabled',
          value: diagnostics.backgroundMonitoringEnabled ? 'Yes' : 'No',
        ),
        _DeveloperInfoTile(
          title: 'Foreground service running',
          value: diagnostics.foregroundServiceRunning ? 'Yes' : 'No',
        ),
        _DeveloperInfoTile(
          title: 'Current destination',
          value: destinationName ?? 'None',
        ),
        _DeveloperInfoTile(
          title: 'Distance remaining',
          value: destinationName == null
              ? '—'
              : '${distanceKm.toStringAsFixed(1)} km',
        ),
        _DeveloperInfoTile(
          title: 'Last location timestamp',
          value: lastUpdated,
        ),
      ],
    );
  }
}

class _DeveloperInfoTile extends StatelessWidget {
  const _DeveloperInfoTile({
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
