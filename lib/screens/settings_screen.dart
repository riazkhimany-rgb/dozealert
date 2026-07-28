import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import '../providers/wear_status_provider.dart';
import '../services/app_tour_service.dart';
import '../utils/trip_ux_copy.dart';
import '../widgets/settings_section_tile.dart';
import 'settings/about_settings_screen.dart';
import 'settings/activity_settings_screen.dart';
import 'settings/alarm_settings_screen.dart';
import 'settings/developer_tools_screen.dart';
import 'settings/location_settings_screen.dart';
import 'settings/permissions_settings_screen.dart';
import 'settings/theme_settings_screen.dart';
import 'settings/transit_settings_screen.dart';
import 'settings/wear_settings_screen.dart';
import 'settings/transit_mode_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.paddingOf(context).bottom + 72,
        ),
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
          SettingsNavTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Permissions',
            subtitle: 'GPS, notifications, battery, and background access',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PermissionsSettingsScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App info, feedback, and version',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AboutSettingsScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.notifications_active_outlined,
            title: TripUxCopy.wakeAlertTitle,
            subtitle: 'Wake by stops or alert distance',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitModeSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Transit'),
          SettingsNavTile(
            icon: Icons.directions_transit_outlined,
            title: 'Transit setup',
            subtitle: 'Agencies, stop lists, and saved lines',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Alarm'),
          SettingsNavTile(
            icon: Icons.alarm_outlined,
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
          if ((Platform.isAndroid || Platform.isIOS) &&
              context.watch<WearStatusProvider>().appInstalled) ...[
            const Divider(height: 32),
            SettingsSectionHeader(
              title: Platform.isIOS ? 'Apple Watch' : 'Wear',
            ),
            SettingsNavTile(
              icon: Icons.watch_outlined,
              title: Platform.isIOS ? 'Apple Watch' : 'Wear OS',
              subtitle: 'Watch companion and trip-start launch',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WearSettingsScreen(),
                  ),
                );
              },
            ),
          ],
          const Divider(height: 32),
          const SettingsSectionHeader(title: TripUxCopy.pastTripsTitle),
          SettingsNavTile(
            key: const Key('settings_trip_history'),
            icon: Icons.history,
            title: TripUxCopy.pastTripsTitle,
            subtitle: TripUxCopy.pastTripsSettingsSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ActivitySettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Location'),
          SettingsNavTile(
            icon: Icons.my_location_outlined,
            title: 'Location',
            subtitle: 'Accuracy, battery, and background trip status',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LocationSettingsScreen(),
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
