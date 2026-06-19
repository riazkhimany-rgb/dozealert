import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/location_format.dart';
import '../widgets/home_card.dart';
import 'settings/developer_tools_screen.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diagnostics = context.select<LocationProvider, BackgroundMonitorDiagnostics>(
      (provider) => provider.backgroundDiagnostics,
    );
    final destinationName = context.select<MonitoringProvider, String?>(
      (provider) => provider.selectedDestination?.name,
    );
    final distanceKm = context.select<LocationProvider, double>(
      (provider) => provider.distanceRemainingKm,
    );
    final lastUpdated = context.select<LocationProvider, String>(
      (provider) {
        final timestamp = provider.currentLocation?.timestamp;
        return timestamp == null
            ? '—'
            : LocationFormat.lastUpdated(timestamp);
      },
    );
    final testModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.testModeEnabled,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeCardHeader(
                  icon: Icons.developer_mode,
                  title: 'Diagnostics',
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  label: 'Background monitoring',
                  value: diagnostics.backgroundMonitoringEnabled ? 'Yes' : 'No',
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Foreground service',
                  value: diagnostics.foregroundServiceRunning ? 'Yes' : 'No',
                ),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Test mode',
                  value: testModeEnabled ? 'On' : 'Off',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeCardHeader(
                  icon: Icons.my_location,
                  title: 'Current GPS',
                ),
                const SizedBox(height: 12),
                _MetricRow(label: 'Destination', value: destinationName ?? 'None'),
                const SizedBox(height: 8),
                _MetricRow(
                  label: 'Distance remaining',
                  value: destinationName == null
                      ? '—'
                      : '${distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(height: 8),
                _MetricRow(label: 'Last updated', value: lastUpdated),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeveloperToolsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.build_outlined),
              label: const Text('Open Developer Tools'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Debug builds only.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
