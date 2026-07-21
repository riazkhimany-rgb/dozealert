import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transit_mode_wake_setting.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/monitoring_format.dart';
import '../utils/trip_ux_copy.dart';
import 'accessible_scroll_body.dart';
import 'wake_radius_dropdown.dart';

/// Compact pre-trip wake controls (stops or alert distance) — not full Settings.
class WakeAlertSheet extends StatelessWidget {
  const WakeAlertSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const WakeAlertSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final transitModeEnabled = settings.transitModeEnabled;
    final radiusMeters = context.select<MonitoringProvider, int>(
      (provider) => provider.radiusMeters,
    );

    return AccessibleSheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TripUxCopy.wakeAlertTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transitModeEnabled
                ? 'Choose how many stops before your destination to wake.'
                : 'Choose how close to your destination to wake.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (transitModeEnabled)
            RadioGroup<TransitModeWakeSetting>(
              groupValue: settings.transitModeWake,
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                await settings.setTransitModeWake(value);
                if (!context.mounted) {
                  return;
                }
                context.read<TransitModeProvider>().refreshFromSettings();
                await context
                    .read<BackgroundMonitorService>()
                    .refreshSessionIfRunning();
              },
              child: Column(
                children: TransitModeWakeSetting.values
                    .map(
                      (wakeSetting) => RadioListTile<TransitModeWakeSetting>(
                        title: Text(wakeSetting.label),
                        value: wakeSetting,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            )
          else
            InputDecorator(
              decoration: InputDecoration(
                labelText: TripUxCopy.alertDistanceLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: radiusMeters,
                  items: WakeRadiusDropdown.radiusOptions
                      .map(
                        (meters) => DropdownMenuItem<int>(
                          value: meters,
                          child: Text(MonitoringFormat.radiusLabel(meters)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    await context.read<MonitoringProvider>().setRadius(value);
                    if (!context.mounted) {
                      return;
                    }
                    await context
                        .read<BackgroundMonitorService>()
                        .refreshSessionIfRunning();
                  },
                ),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
