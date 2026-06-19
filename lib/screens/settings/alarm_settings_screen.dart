import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alarm_sound_mode.dart';
import '../../providers/settings_provider.dart';
import '../../services/alarm_service.dart';
import '../../widgets/settings_section_tile.dart';

class AlarmSettingsScreen extends StatelessWidget {
  const AlarmSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alarmService = context.read<AlarmService>();
    final alarmSoundMode = context.select<SettingsProvider, AlarmSoundMode>(
      (provider) => provider.alarmSoundMode,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Sound Override'),
          SwitchListTile(
            secondary: Icon(Icons.volume_up_outlined, color: colorScheme.primary),
            title: const Text('Always play sound'),
            subtitle: Text(
              AlarmSoundMode.alwaysPlaySound.description,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: alarmSoundMode == AlarmSoundMode.alwaysPlaySound,
            onChanged: (enabled) {
              context.read<SettingsProvider>().setAlarmSoundMode(
                enabled
                    ? AlarmSoundMode.alwaysPlaySound
                    : AlarmSoundMode.followDevice,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              alarmSoundMode == AlarmSoundMode.alwaysPlaySound
                  ? 'DozeAlert uses the alarm audio stream so sound plays even '
                      'when your phone is on vibrate or silent. Make sure your '
                      'alarm volume is turned up in system settings.'
                  : AlarmSoundMode.followDevice.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Alarm Sound'),
          ListTile(
            leading: Icon(Icons.music_note_outlined, color: colorScheme.primary),
            title: const Text('Alarm Sound'),
            subtitle: Text(
              'Default arrival alarm',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Text('alarm.mp3'),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Vibration'),
          ListTile(
            leading: Icon(Icons.vibration, color: colorScheme.primary),
            title: const Text('Vibration'),
            subtitle: Text(
              'Vibration is always enabled when supported.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Text('On'),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Test Alarm'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
              onPressed: () async {
                await alarmService.playAlarm();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing test alarm. Tap Stop to silence.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Test Alarm'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => alarmService.stopAlarm(),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop Alarm'),
            ),
          ),
        ],
      ),
    );
  }
}
