import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/alarm_service.dart';
import '../../widgets/settings_section_tile.dart';

class AlarmSettingsScreen extends StatelessWidget {
  const AlarmSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alarmService = context.read<AlarmService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm'),
      ),
      body: ListView(
        children: [
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
          const SettingsSectionHeader(title: 'Volume'),
          ListTile(
            leading: Icon(Icons.volume_up_outlined, color: colorScheme.primary),
            title: const Text('Volume'),
            subtitle: Text(
              'Uses system media volume.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Vibration'),
          ListTile(
            leading: Icon(Icons.vibration, color: colorScheme.primary),
            title: const Text('Vibration'),
            subtitle: Text(
              'Vibration enabled when supported.',
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
