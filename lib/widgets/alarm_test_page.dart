import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../services/alarm_service.dart';
import '../utils/app_branding.dart';

class AlarmTestPage extends StatelessWidget {
  const AlarmTestPage({
    super.key,
    required this.alarmPlaying,
    required this.alarmTestCompleted,
    required this.onPlay,
    required this.onStop,
    this.showCompletionHint = true,
    this.completionMessage =
        'Volume saved. You can close this screen when ready.',
  });

  final bool alarmPlaying;
  final bool alarmTestCompleted;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final bool showCompletionHint;
  final String completionMessage;

  static int _percentLabel(double value) => (value * 100).round();

  Future<void> _applyVolumeChange(
    AlarmService alarmService,
    Future<void> Function(double) saveVolume,
    double value,
  ) async {
    await saveVolume(value);
    await alarmService.updateActiveAlarmVolume();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.read<SettingsProvider>();
    final alarmService = context.read<AlarmService>();
    final alarmVolume = context.select<SettingsProvider, double>(
      (provider) => provider.alarmVolume,
    );
    final approachSystemVolume = context.select<SettingsProvider, double>(
      (provider) => provider.approachSystemVolume,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Icon(
          Icons.volume_up_outlined,
          size: 64,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Test the alarm',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Play the alert, adjust the sliders until it is easy to hear, '
          'then stop the test when you are done.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Phone speaker volume during alert',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            Icon(Icons.volume_down, color: colorScheme.onSurfaceVariant),
            Expanded(
              child: Slider(
                value: approachSystemVolume,
                min: AppSettings.minApproachSystemVolume,
                max: 1.0,
                divisions: 18,
                label: '${_percentLabel(approachSystemVolume)}%',
                onChanged: (value) => unawaited(
                  _applyVolumeChange(
                    alarmService,
                    settingsProvider.setApproachSystemVolume,
                    value,
                  ),
                ),
              ),
            ),
            Icon(Icons.volume_up, color: colorScheme.onSurfaceVariant),
          ],
        ),
        Text(
          'Temporarily raises media volume while the alert plays.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Voice and tone level',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            Icon(Icons.volume_down, color: colorScheme.onSurfaceVariant),
            Expanded(
              child: Slider(
                value: alarmVolume,
                divisions: 10,
                label: '${_percentLabel(alarmVolume)}%',
                onChanged: (value) => unawaited(
                  _applyVolumeChange(
                    alarmService,
                    settingsProvider.setAlarmVolume,
                    value,
                  ),
                ),
              ),
            ),
            Icon(Icons.volume_up, color: colorScheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: alarmPlaying ? null : onPlay,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play test alarm'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: alarmPlaying ? onStop : null,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Stop test alarm'),
        ),
        if (showCompletionHint && alarmTestCompleted) ...[
          const SizedBox(height: 16),
          Text(
            completionMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          AppBranding.tagline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
