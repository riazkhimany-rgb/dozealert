import 'package:flutter/material.dart';

import '../../widgets/settings_section_tile.dart';
import '../../widgets/transit_preferences_section.dart';
import '../gtfs_import_screen.dart';
import '../transit_data_screen.dart';
import 'transit_mode_settings_screen.dart';

class TransitSettingsScreen extends StatelessWidget {
  const TransitSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit'),
      ),
      body: ListView(
        children: [
          SettingsNavTile(
            icon: Icons.cloud_download_outlined,
            title: 'Transit Data',
            subtitle: 'Download, update, and delete GTFS feeds',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitDataScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.directions_transit,
            title: 'Transit Mode',
            subtitle: 'Stop-based wake alarms for all vehicle types',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitModeSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Preferred Agencies'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Choose which agencies appear first in search and trip setup.',
            ),
          ),
          const SizedBox(height: 8),
          SettingsNavTile(
            icon: Icons.apartment_outlined,
            title: 'Preferred Agencies',
            subtitle: 'GO Transit, TTC, YRT, MiWay, and more',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _PreferredAgenciesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Favorite Stops'),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Favorite Stops'),
            subtitle: const Text('Manage favorites from the Trips tab.'),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Advanced'),
          SettingsNavTile(
            icon: Icons.upload_file_outlined,
            title: 'Import GTFS Zip',
            subtitle: 'Manually import a transit feed file',
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

class _PreferredAgenciesScreen extends StatelessWidget {
  const _PreferredAgenciesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferred Agencies'),
      ),
      body: ListView(
        children: const [
          TransitPreferencesSection(),
        ],
      ),
    );
  }
}
