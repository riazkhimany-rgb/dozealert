import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../models/train_mode_snapshot.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/train_mode_provider.dart';
import '../providers/transit_provider.dart';
import '../services/background_monitor_service.dart';
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

  @override
  Widget build(BuildContext context) {
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
        children: const [
          _DestinationCard(),
          SizedBox(height: 16),
          _MonitoringCard(),
          SizedBox(height: 16),
          _DistanceCard(),
          SizedBox(height: 16),
          _RecentDestinationsCard(),
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

class _DestinationCard extends StatelessWidget {
  const _DestinationCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );
    final snapshot = context.select<TrainModeProvider, TrainModeSnapshot>(
      (provider) => provider.snapshot,
    );

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.location_on_outlined,
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
            label: 'Current Station',
            value: snapshot.isActive
                ? snapshot.currentNearestStation?.stopName ?? '—'
                : '—',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Next Station',
            value: snapshot.isActive
                ? snapshot.nextStation?.stopName ?? '—'
                : '—',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Stations Remaining',
            value: snapshot.isActive
                ? snapshot.stationsRemaining.toString()
                : '—',
          ),
          const SizedBox(height: 20),
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
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Change Destination'),
            ),
          ),
          if (destination == null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DestinationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Choose Destination'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.select<MonitoringProvider, MonitoringState>(
      (provider) => provider.currentState,
    );
    final hasDestination = context.select<MonitoringProvider, bool>(
      (provider) => provider.selectedDestination != null,
    );
    final statusColor = _statusColor(colorScheme, state);
    final canStart = hasDestination && state == MonitoringState.idle;
    final canStop = state == MonitoringState.monitoring ||
        state == MonitoringState.arrived;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.sensors,
            title: 'Monitoring',
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
                  'Status: ${MonitoringFormat.homeStatusLabel(state)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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
          if (!hasDestination) ...[
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
    final locationProvider = context.read<LocationProvider>();
    final backgroundMonitorService = context.read<BackgroundMonitorService>();

    Future<void> tryStart({bool resume = false}) async {
      final result = await locationProvider.startTracking(resume: resume);
      if (!context.mounted) {
        return;
      }

      await LocationFeedback.handleStartResult(
        context,
        result,
        backgroundMonitorService: backgroundMonitorService,
        onContinueAfterBatteryPrompt: result ==
                LocationStartResult.batteryOptimizationRequired
            ? () => tryStart(resume: true)
            : null,
      );
    }

    await tryStart();
  }

  Future<void> _handleStopMonitoring(BuildContext context) async {
    await context.read<LocationProvider>().stopTracking();
  }

  Color _statusColor(ColorScheme colorScheme, MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => colorScheme.onSurfaceVariant,
      MonitoringState.monitoring => colorScheme.primary,
      MonitoringState.arrived => Colors.green,
      MonitoringState.missed => colorScheme.error,
    };
  }

  IconData _statusIcon(MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => Icons.hourglass_empty_outlined,
      MonitoringState.monitoring => Icons.radar,
      MonitoringState.arrived => Icons.directions_railway,
      MonitoringState.missed => Icons.error_outline,
    };
  }
}

class _DistanceCard extends StatelessWidget {
  const _DistanceCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDestination = context.select<LocationProvider, bool>(
      (provider) => provider.hasDestination,
    );
    final distanceKm = context.select<LocationProvider, double>(
      (provider) => provider.distanceRemainingKm,
    );
    final speedLabel = context.select<LocationProvider, String>(
      (provider) {
        final location = provider.currentLocation;
        return location == null
            ? '—'
            : '${location.speedKmh.toStringAsFixed(1)} km/h';
      },
    );

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.straighten,
            title: 'Distance',
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
          const SizedBox(height: 12),
          _MetricRow(label: 'Current speed', value: speedLabel),
        ],
      ),
    );
  }
}

class _RecentDestinationsCard extends StatelessWidget {
  const _RecentDestinationsCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentDestinations = context.select<TransitProvider, List<Destination>>(
      (provider) => provider.recentStations.take(5).toList(growable: false),
    );

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.history,
            title: 'Recent Destinations',
          ),
          const SizedBox(height: 12),
          if (recentDestinations.isEmpty)
            Text(
              'No recent destinations yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...recentDestinations.map(
              (destination) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place_outlined),
                title: Text(destination.name),
                onTap: () {
                  context.read<MonitoringProvider>().setDestination(destination);
                },
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
