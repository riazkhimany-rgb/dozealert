import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/current_location.dart';
import '../models/monitoring_state.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../utils/location_format.dart';
import '../utils/monitoring_format.dart';
import '../widgets/arrival_dialog.dart';
import '../widgets/home_card.dart';
import 'destination_screen.dart';
import 'map_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showingArrivalDialog = false;

  static const _radiusOptions = <int>[250, 500, 1000, 2000];

  @override
  Widget build(BuildContext context) {
    final monitoring = context.watch<MonitoringProvider>();
    final arrivalVisible = context.select<LocationProvider, bool>(
      (provider) => provider.arrivalDialogVisible,
    );

    if (arrivalVisible && !_showingArrivalDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_presentArrivalDialog());
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DozeAlert'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _ArrivalStatusCard(state: monitoring.currentState),
          const SizedBox(height: 16),
          _DestinationCard(monitoring: monitoring),
          const SizedBox(height: 16),
          const _CurrentLocationCard(),
          const SizedBox(height: 16),
          const _DistanceRemainingCard(),
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

  Future<void> _presentArrivalDialog() async {
    if (!mounted || _showingArrivalDialog) {
      return;
    }

    _showingArrivalDialog = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          child: ArrivalDialog(
            onDismiss: () async {
              Navigator.of(dialogContext).pop();
              await context.read<LocationProvider>().dismissArrival();
            },
          ),
        );
      },
    );

    if (mounted) {
      _showingArrivalDialog = false;
    }
  }
}

class _ArrivalStatusCard extends StatelessWidget {
  const _ArrivalStatusCard({required this.state});

  final MonitoringState state;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(state);
    final statusLabel = _statusLabel(state);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.flag_outlined,
            title: 'Arrival Status',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(state), color: statusColor),
                const SizedBox(width: 12),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => Colors.grey,
      MonitoringState.monitoring => Colors.blue,
      MonitoringState.arrived => Colors.green,
      MonitoringState.missed => Colors.orange,
    };
  }

  String _statusLabel(MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => 'Idle',
      MonitoringState.monitoring => 'Monitoring',
      MonitoringState.arrived => 'Arrived',
      MonitoringState.missed => 'Missed',
    };
  }

  IconData _statusIcon(MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => Icons.hourglass_empty_outlined,
      MonitoringState.monitoring => Icons.radar,
      MonitoringState.arrived => Icons.check_circle_outline,
      MonitoringState.missed => Icons.error_outline,
    };
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
  const _CurrentLocationCard();

  @override
  Widget build(BuildContext context) {
    return Selector<LocationProvider, CurrentLocation?>(
      selector: (_, provider) => provider.currentLocation,
      builder: (context, location, _) {
        final tracking = context.select<LocationProvider, bool>(
          (provider) => provider.trackingEnabled,
        );

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
                value: location != null
                    ? location.latitude.toStringAsFixed(4)
                    : '—',
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Longitude',
                value: location != null
                    ? location.longitude.toStringAsFixed(4)
                    : '—',
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Speed',
                value: location != null
                    ? '${location.speedKmh.toStringAsFixed(1)} km/h'
                    : '—',
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Accuracy',
                value: location != null
                    ? '${location.accuracy.toStringAsFixed(0)} m'
                    : '—',
              ),
              const SizedBox(height: 12),
              _MetricRow(
                label: 'Last updated',
                value: location != null
                    ? LocationFormat.lastUpdated(location.timestamp)
                    : '—',
              ),
              if (!tracking) ...[
                const SizedBox(height: 8),
                Text(
                  'Start monitoring to update your location.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DistanceRemainingCard extends StatelessWidget {
  const _DistanceRemainingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDestination = context.select<LocationProvider, bool>(
      (provider) => provider.hasDestination,
    );
    final distanceKm = context.select<LocationProvider, double>(
      (provider) => provider.distanceRemainingKm,
    );

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
            hasDestination
                ? '${distanceKm.toStringAsFixed(1)} km'
                : 'No destination selected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasDestination
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
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
        monitoring.currentState == MonitoringState.idle;
    final canStop = monitoring.currentState == MonitoringState.monitoring ||
        monitoring.currentState == MonitoringState.arrived;

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
                  ? () => _handleStartMonitoring(context)
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
              onPressed: canStop ? () => _handleStopMonitoring(context) : null,
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

  Future<void> _handleStartMonitoring(BuildContext context) async {
    final result = await context.read<LocationProvider>().startTracking();
    if (!context.mounted) {
      return;
    }
    await LocationFeedback.handleStartResult(context, result);
  }

  Future<void> _handleStopMonitoring(BuildContext context) async {
    await context.read<LocationProvider>().stopTracking();
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
      MonitoringState.arrived => Colors.green,
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
