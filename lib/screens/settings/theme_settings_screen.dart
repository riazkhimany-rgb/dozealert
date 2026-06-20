import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../widgets/settings_section_tile.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Appearance'),
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
        ],
      ),
    );
  }
}
