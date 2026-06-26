import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import '../services/app_tour_service.dart';
import '../widgets/settings_section_tile.dart';
import 'settings/about_settings_screen.dart';
import 'settings/alarm_settings_screen.dart';
import 'settings/developer_tools_screen.dart';
import 'settings/location_settings_screen.dart';
import 'settings/theme_settings_screen.dart';
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
            subtitle: 'Light, dark, and system appearance',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App info, our story, and version',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AboutSettingsScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.explore_outlined,
            title: 'Show app tour',
            subtitle: 'Walk through each Home step again',
            onTap: () {
              context.read<NavigationProvider>().setIndex(0);
              context.read<AppTourService>().requestReplay();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tour starting on Home.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Transit'),
          SettingsNavTile(
            icon: Icons.directions_transit_outlined,
            title: 'Transit',
            subtitle: 'Transit data, transit mode, and agencies',
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
