import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transit_mode_wake_setting.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transit_mode_provider.dart';
import '../../services/background_monitor_service.dart';
import '../../utils/trip_ux_copy.dart';
import '../../widgets/branded_app_name.dart';
import '../../widgets/settings_section_tile.dart';
import '../../widgets/wake_radius_dropdown.dart';

class TransitModeSettingsScreen extends StatelessWidget {
  const TransitModeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final transitModeEnabled = settingsProvider.transitModeEnabled;

    final wakeTimingGroup = RadioGroup<TransitModeWakeSetting>(
      groupValue: settingsProvider.transitModeWake,
      onChanged: (value) async {
        if (!transitModeEnabled || value == null) {
          return;
        }
        await settingsProvider.setTransitModeWake(value);
        if (!context.mounted) {
          return;
        }
        context.read<TransitModeProvider>().refreshFromSettings();
        await context.read<BackgroundMonitorService>().refreshSessionIfRunning();
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
      appBar: AppBar(title: const Text(TripUxCopy.wakeAlertTitle)),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: TripUxCopy.wakeAlertTitle),
          SwitchListTile(
            secondary: Icon(
              Icons.directions_transit,
              color: colorScheme.primary,
            ),
            title: const Text('Wake by stops'),
            subtitle: Text(
              transitModeEnabled
                  ? 'On — wake by stops when you are on your transit route.'
                  : 'Off — wake by alert distance only.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: transitModeEnabled,
            onChanged: (enabled) async {
              await settingsProvider.setTransitModeEnabled(enabled);
              if (!context.mounted) {
                return;
              }
              context.read<TransitModeProvider>().refreshFromSettings();
              await context
                  .read<BackgroundMonitorService>()
                  .refreshSessionIfRunning();
            },
          ),
          if (transitModeEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Choose how many stops before your destination the alarm should sound.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          if (transitModeEnabled) ...[
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
            wakeTimingGroup,
          ],
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Distance fallback'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: BrandedMentionText(
              transitModeEnabled
                  ? 'For map-pin destinations or when you are not on a transit route, '
                        'DozeAlert uses straight-line distance instead of stops. '
                        'Transit stop destinations wake by stops once you are on the route.'
                  : 'With wake by stops off, DozeAlert always wakes you by straight-line '
                        'distance to your destination.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const WakeRadiusDropdown(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
