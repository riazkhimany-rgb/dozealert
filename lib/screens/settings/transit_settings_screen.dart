import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/train_mode_wake_setting.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/settings_section_tile.dart';
import '../../widgets/transit_preferences_section.dart';
import '../gtfs_import_screen.dart';

class TransitSettingsScreen extends StatelessWidget {
  const TransitSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Preferred Agencies'),
          const TransitPreferencesSection(),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Train Mode'),
          SwitchListTile(
            secondary: Icon(Icons.directions_railway, color: colorScheme.primary),
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
              'Wake One Station Before',
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
          const SettingsSectionHeader(title: 'Favorite Stations'),
          ListTile(
            leading: Icon(Icons.star_outline, color: colorScheme.primary),
            title: const Text('Favorite Stations'),
            subtitle: Text(
              'Manage favorites from the Trips tab.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'GTFS Data'),
          SettingsNavTile(
            icon: Icons.upload_file_outlined,
            title: 'Import GTFS Feed',
            subtitle: 'GO Transit, TTC, STM, Exo, Amtrak, National Rail',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GtfsImportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
