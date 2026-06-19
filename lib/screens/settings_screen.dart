import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/settings_section_tile.dart';
import 'settings/alarm_settings_screen.dart';
import 'settings/developer_tools_screen.dart';
import 'settings/general_settings_screen.dart';
import 'settings/location_settings_screen.dart';
import 'settings/transit_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'General'),
          SettingsNavTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Appearance, about, and version',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GeneralSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Transit'),
          SettingsNavTile(
            icon: Icons.directions_transit_outlined,
            title: 'Transit',
            subtitle: 'Agencies, train mode, favorites, GTFS data',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Location'),
          SettingsNavTile(
            icon: Icons.my_location_outlined,
            title: 'Location',
            subtitle: 'Wake radius, accuracy, battery, background',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LocationSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Alarm'),
          SettingsNavTile(
            icon: Icons.notifications_active_outlined,
            title: 'Alarm',
            subtitle: 'Sound, volume, vibration, test alarm',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AlarmSettingsScreen(),
                ),
              );
            },
          ),
          if (kDebugMode) ...[
            const Divider(height: 32),
            const SettingsSectionHeader(title: 'Developer'),
            SettingsNavTile(
              icon: Icons.developer_mode,
              title: 'Developer Tools',
              subtitle: 'Diagnostics, GPS, logs, debug info',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeveloperToolsScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
