import 'package:flutter/material.dart';

import '../../widgets/settings_section_tile.dart';
import 'favorite_lines_settings_screen.dart';
import '../transit_data_screen.dart';
import 'preferred_agencies_screen.dart';
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
            subtitle: 'Wake timing and distance fallback (toggle on Home)',
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
              'Choose your country, province or state, and preferred transit agency.',
            ),
          ),
          const SizedBox(height: 8),
          SettingsNavTile(
            icon: Icons.apartment_outlined,
            title: 'Preferred Agencies',
            subtitle: 'GTA and Ontario agencies by region',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PreferredAgenciesScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.star_outline,
            title: 'Favorite Lines',
            subtitle: 'Saved transit lines for quick switching',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FavoriteLinesSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
