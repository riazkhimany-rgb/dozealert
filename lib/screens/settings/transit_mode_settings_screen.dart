import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transit_mode_wake_setting.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transit_mode_provider.dart';
import '../../widgets/branded_app_name.dart';
import '../../widgets/settings_section_tile.dart';

class TransitModeSettingsScreen extends StatelessWidget {
  const TransitModeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final transitModeEnabled = settingsProvider.transitModeEnabled;

    final wakeTimingGroup = RadioGroup<TransitModeWakeSetting>(
      groupValue: settingsProvider.transitModeWake,
      onChanged: (value) {
        if (!transitModeEnabled || value == null) {
          return;
        }
        context.read<TransitModeProvider>().refreshFromSettings();
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
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Mode'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Transit Mode'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Turn Transit Mode on or off from the switch on Home. '
              'Choose how many stops before your station the alarm should sound.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          if (!transitModeEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Transit Mode is off. Turn it on from the switch on '
                        'Home to change wake timing.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
          if (transitModeEnabled)
            wakeTimingGroup
          else
            IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: wakeTimingGroup,
              ),
            ),
          const Divider(height: 32),
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: colorScheme.primary),
            title: const Text('Distance fallback'),
            subtitle: BrandedMentionText(
              'For map-pin destinations when you are not on a transit route, '
              'DozeAlert uses your wake radius and straight-line distance instead. '
              'GTFS stop destinations always wake by stops once you are on the route.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
