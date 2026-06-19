import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/monitoring_state.dart';
import '../providers/monitoring_provider.dart';
import '../utils/monitoring_format.dart';
import '../widgets/home_card.dart';
import 'destination_screen.dart';
import 'map_picker_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _mockLatitude = 43.6532;
  static const _mockLongitude = -79.3832;
  static const _mockSpeedKmh = 0.0;
  static const _mockDistanceKm = 0.0;
  static const _radiusOptions = <int>[250, 500, 1000, 2000];

  @override
  Widget build(BuildContext context) {
    final monitoring = context.watch<MonitoringProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DozeAlert'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _DestinationCard(monitoring: monitoring),
          const SizedBox(height: 16),
          const _CurrentLocationCard(
            latitude: _mockLatitude,
            longitude: _mockLongitude,
            speedKmh: _mockSpeedKmh,
          ),
          const SizedBox(height: 16),
          const _DistanceRemainingCard(distanceKm: _mockDistanceKm),
          const SizedBox(height: 16),
          _WakeUpRadiusCard(
            selectedRadius: monitoring.radiusMeters,
            options: _radiusOptions,
            onRadiusChanged: context.read<MonitoringProvider>().setRadius,
          ),
          const SizedBox(height: 16),
          _MonitoringControlsCard(monitoring: monitoring),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.monitoring});

  final MonitoringProvider monitoring;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = monitoring.selectedDestination;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.location_on,
            title: 'Destination',
          ),
          const SizedBox(height: 16),
          Text(
            destination?.name ?? 'No destination selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: destination == null
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Latitude',
            value: destination != null
                ? destination.latitude.toStringAsFixed(4)
                : '—',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Longitude',
            value: destination != null
                ? destination.longitude.toStringAsFixed(4)
                : '—',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DestinationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Choose Destination'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MapPickerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Change Destination'),
            ),
          ),
          if (destination != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<MonitoringProvider>().clearDestination();
                },
                icon: const Icon(Icons.clear_outlined),
                label: const Text('Clear Destination'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
  });

  final double latitude;
  final double longitude;
  final double speedKmh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.my_location,
            title: 'Current Location',
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: 'Latitude',
            value: latitude.toStringAsFixed(4),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Longitude',
            value: longitude.toStringAsFixed(4),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Speed',
            value: '${speedKmh.toStringAsFixed(0)} km/h',
          ),
          const SizedBox(height: 4),
          Text(
            'Mock location data',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _DistanceRemainingCard extends StatelessWidget {
  const _DistanceRemainingCard({required this.distanceKm});

  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.directions_transit,
            title: 'Distance Remaining',
          ),
          const SizedBox(height: 16),
          Text(
            '${distanceKm.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WakeUpRadiusCard extends StatelessWidget {
  const _WakeUpRadiusCard({
    required this.selectedRadius,
    required this.options,
    required this.onRadiusChanged,
  });

  final int selectedRadius;
  final List<int> options;
  final ValueChanged<int> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.tune,
            title: 'Wake-Up Radius',
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Alert distance',
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
                value: selectedRadius,
                items: options
                    .map(
                      (meters) => DropdownMenuItem<int>(
                        value: meters,
                        child: Text(MonitoringFormat.radiusLabel(meters)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onRadiusChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringControlsCard extends StatelessWidget {
  const _MonitoringControlsCard({required this.monitoring});

  final MonitoringProvider monitoring;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canStart = monitoring.selectedDestination != null &&
        monitoring.currentState != MonitoringState.monitoring;
    final canStop = monitoring.currentState != MonitoringState.idle;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.notifications_active_outlined,
            title: 'Monitoring Controls',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _stateIcon(monitoring.currentState),
                  color: _stateColor(colorScheme, monitoring.currentState),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current state',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  MonitoringFormat.stateLabel(monitoring.currentState),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _stateColor(colorScheme, monitoring.currentState),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: canStart
                  ? context.read<MonitoringProvider>().startMonitoring
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Monitoring'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.tonalIcon(
              onPressed: canStop
                  ? context.read<MonitoringProvider>().stopMonitoring
                  : null,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop Monitoring'),
            ),
          ),
          if (monitoring.selectedDestination == null) ...[
            const SizedBox(height: 12),
            Text(
              'Choose a destination before starting monitoring.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _stateIcon(MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => Icons.pause_circle_outline,
      MonitoringState.monitoring => Icons.sensors,
      MonitoringState.arrived => Icons.check_circle_outline,
      MonitoringState.missed => Icons.error_outline,
    };
  }

  Color _stateColor(ColorScheme colorScheme, MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => colorScheme.onSurfaceVariant,
      MonitoringState.monitoring => colorScheme.primary,
      MonitoringState.arrived => colorScheme.tertiary,
      MonitoringState.missed => colorScheme.error,
    };
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
