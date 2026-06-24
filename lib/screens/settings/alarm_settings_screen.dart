import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alarm_sound_mode.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../services/alarm_service.dart';
import '../../widgets/settings_section_tile.dart';

class AlarmSettingsScreen extends StatelessWidget {
  const AlarmSettingsScreen({super.key});

  static int _percentLabel(double value) => (value * 100).round();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alarmService = context.read<AlarmService>();
    final alarmSoundMode = context.select<SettingsProvider, AlarmSoundMode>(
      (provider) => provider.alarmSoundMode,
    );
    final alarmVolume = context.select<SettingsProvider, double>(
      (provider) => provider.alarmVolume,
    );
    final approachSystemVolume = context.select<SettingsProvider, double>(
      (provider) => provider.approachSystemVolume,
    );
    final vibrationIntensity = context.select<SettingsProvider, double>(
      (provider) => provider.vibrationIntensity,
    );
    final alwaysPlaySound =
        alarmSoundMode == AlarmSoundMode.alwaysPlaySound;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Approach Alert'),
          ListTile(
            leading: Icon(Icons.record_voice_over_outlined,
                color: colorScheme.primary),
            title: const Text('Voice alert'),
            subtitle: Text(
              'Always speaks "Heads up! Approaching destination." with '
              'vibration until you dismiss. Phone speaker volume is temporarily '
              'adjusted during the alert, then restored.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              'Speaker volume during alert',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Icon(Icons.volume_down, color: colorScheme.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: approachSystemVolume,
                    min: AppSettings.minApproachSystemVolume,
                    max: 1.0,
                    divisions: 18,
                    label: '${_percentLabel(approachSystemVolume)}%',
                    onChanged:
                        context.read<SettingsProvider>().setApproachSystemVolume,
                  ),
                ),
                Icon(Icons.volume_up, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Sets media volume to ${_percentLabel(approachSystemVolume)}% while '
              'the alert plays, even if your phone volume is lower. Your previous '
              'level is restored when you dismiss.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Voice & Tone Level'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Icon(Icons.volume_down, color: colorScheme.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: alarmVolume,
                    divisions: 10,
                    label: '${_percentLabel(alarmVolume)}%',
                    onChanged: context.read<SettingsProvider>().setAlarmVolume,
                  ),
                ),
                Icon(Icons.volume_up, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Controls how loud the spoken alert and optional alarm tone play.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Alarm Sound Override'),
          SwitchListTile(
            secondary: Icon(Icons.volume_up_outlined, color: colorScheme.primary),
            title: const Text('Always play alarm sound'),
            subtitle: Text(
              AlarmSoundMode.alwaysPlaySound.description,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: alwaysPlaySound,
            onChanged: (enabled) {
              context.read<SettingsProvider>().setAlarmSoundMode(
                enabled
                    ? AlarmSoundMode.alwaysPlaySound
                    : AlarmSoundMode.followDevice,
              );
            },
          ),
          if (alwaysPlaySound)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Uses the alarm audio stream so the tone plays even when your phone '
                'is on vibrate or silent.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                AlarmSoundMode.followDevice.description,
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
              'Optional looped tone when override is enabled',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Text('alarm.mp3'),
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Vibration'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Icon(Icons.vibration, color: colorScheme.onSurfaceVariant),
                Expanded(
                  child: Slider(
                    value: vibrationIntensity,
                    min: AppSettings.minVibrationIntensity,
                    max: 1.0,
                    divisions: 18,
                    label: '${_percentLabel(vibrationIntensity)}%',
                    onChanged: (value) async {
                      await context
                          .read<SettingsProvider>()
                          .setVibrationIntensity(value);
                      if (!context.mounted) {
                        return;
                      }
                      await alarmService.updateActiveAlarmVibration();
                    },
                  ),
                ),
                Icon(Icons.smartphone, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Vibration is always on when supported. Intensity applies on '
              'devices with amplitude control.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
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
                    content: Text(
                      'Playing approach alert. Tap Stop to silence.',
                    ),
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
