import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transit_mode_wake_setting.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings_section_tile.dart';

class TransitModeSettingsScreen extends StatelessWidget {
  const TransitModeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Mode'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Transit Mode'),
          SwitchListTile(
            secondary: Icon(Icons.directions_transit, color: colorScheme.primary),
            title: const Text('Enable Transit Mode'),
            subtitle: Text(
              'Wake up based on stops remaining for trains, buses, subway, '
              'and streetcars.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: settingsProvider.transitModeEnabled,
            onChanged: settingsProvider.setTransitModeEnabled,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'Wake Timing',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          RadioGroup<TransitModeWakeSetting>(
            groupValue: settingsProvider.transitModeWake,
            onChanged: (value) {
              if (!settingsProvider.transitModeEnabled || value == null) {
                return;
              }
              settingsProvider.setTransitModeWake(value);
            },
            child: Column(
              children: TransitModeWakeSetting.values
                  .map(
                    (wakeSetting) => RadioListTile<TransitModeWakeSetting>(
                      title: Text(wakeSetting.label),
                      value: wakeSetting,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: colorScheme.primary),
            title: const Text('Distance fallback'),
            subtitle: Text(
              'When stop sequence is unavailable, DozeAlert falls back to '
              'distance-based wake alarms.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
