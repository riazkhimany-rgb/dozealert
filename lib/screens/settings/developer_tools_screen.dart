import 'package:flutter/material.dart';

import '../../widgets/settings_section_tile.dart';
import '../developer_dashboard_screen.dart';

class DeveloperToolsScreen extends StatelessWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Developer Dashboard'),
          SettingsNavTile(
            icon: Icons.dashboard_outlined,
            title: 'Open Developer Dashboard',
            subtitle: 'Live status, trip history, diagnostics, export',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DeveloperDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
