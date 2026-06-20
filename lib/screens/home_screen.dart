import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_vehicle_type.dart';
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/location_format.dart';
import '../utils/monitoring_format.dart';
import '../utils/wake_radius_format.dart';
import '../widgets/arrival_dialog.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/gtfs_readiness_banner.dart';
import '../widgets/home_card.dart';
import '../widgets/metric_row.dart';
import '../widgets/trip_setup_checklist.dart';
import 'settings/location_settings_screen.dart';
import 'settings/transit_mode_settings_screen.dart';

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
        children: [
          const _MonitoringCard(),
          const SizedBox(height: 16),
          const TripSetupChecklist(),
          const GtfsReadinessBanner(),
          const _DestinationCard(),
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
    final snapshot = context.select<TransitModeProvider, TransitModeSnapshot>(
      (provider) => provider.snapshot,
    );
    final transitModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final selectedLine = context.select<GtfsProvider, String>(
      (provider) => provider.selectedLineLabel,
    );
    final state = context.select<MonitoringProvider, MonitoringState>(
      (provider) => provider.currentState,
    );
    final isMonitoring = state == MonitoringState.monitoring;

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
          if (transitModeEnabled) ...[
            MetricRow(
              label: 'Current Stop',
              value: snapshot.isActive
                  ? snapshot.currentStop?.stopName ?? '—'
                  : '—',
            ),
            const SizedBox(height: 8),
            MetricRow(
              label: 'Next Stop',
              value: snapshot.isActive
                  ? snapshot.nextStop?.stopName ?? '—'
                  : '—',
            ),
            const SizedBox(height: 8),
            MetricRow(
              label: 'Destination Stop',
              value: snapshot.isActive
                  ? snapshot.destinationStop?.stopName ?? '—'
                  : '—',
            ),
            const SizedBox(height: 8),
            MetricRow(
              label: 'Stops Remaining',
              value: snapshot.isActive
                  ? snapshot.stopsRemaining.toString()
                  : '—',
            ),
            const SizedBox(height: 8),
            MetricRow(
              label: 'Vehicle Type',
              value: snapshot.isActive
                  ? snapshot.vehicleType?.label ?? '—'
                  : '—',
            ),
            const SizedBox(height: 12),
          ],
          Semantics(
            button: true,
            label: destination == null
                ? 'Set destination'
                : 'Change destination',
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isMonitoring
                    ? null
                    : () => DestinationPickerSheet.show(context),
                icon: Icon(
                  destination == null
                      ? Icons.add_location_alt_outlined
                      : Icons.edit_location_alt_outlined,
                ),
                label: Text(
                  destination == null ? 'Set destination' : 'Change destination',
                ),
              ),
            ),
          ),
          if (destination != null && !isMonitoring) ...[
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: 'Clear destination',
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<MonitoringProvider>().clearDestination(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear destination'),
                ),
              ),
            ),
          ],
          if (destination != null) ...[
            const SizedBox(height: 12),
            Text(
              transitModeEnabled
                  ? selectedLine
                  : '$selectedLine · Wake by distance when monitoring',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
    final radiusMeters = context.select<MonitoringProvider, int>(
      (provider) => provider.radiusMeters,
    );
    final hasDistance = context.select<LocationProvider, bool>(
      (provider) => provider.distanceIsReady,
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
    final statusColor = _statusColor(colorScheme, state);
    final transitModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final transitWakeLabel = context.select<SettingsProvider, String>(
      (provider) => provider.transitModeWake.label,
    );
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
          Semantics(
            label: 'Monitoring status ${MonitoringFormat.homeStatusLabel(state)}',
            child: Container(
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
                  Expanded(
                    child: Text(
                      'Status: ${MonitoringFormat.homeStatusLabel(state)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            !hasDestination
                ? 'No destination selected'
                : hasDistance
                    ? '${distanceKm.toStringAsFixed(1)} km remaining'
                    : state == MonitoringState.monitoring
                        ? 'Waiting for GPS fix…'
                        : '—',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: hasDistance
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasDestination) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: Icon(
                  Icons.radar_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text(WakeRadiusFormat.alertDescription(radiusMeters)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LocationSettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          MetricRow(label: 'Current speed', value: speedLabel),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.directions_transit_outlined,
              color: colorScheme.primary,
            ),
            title: const Text('Transit Mode'),
            subtitle: Text(
              transitModeEnabled
                  ? 'Wake by stops ($transitWakeLabel)'
                  : 'Wake by distance to destination',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: transitModeEnabled,
            onChanged: state == MonitoringState.monitoring
                ? null
                : (enabled) async {
                    final settingsProvider = context.read<SettingsProvider>();
                    await settingsProvider.setTransitModeEnabled(enabled);
                    if (context.mounted) {
                      context
                          .read<TransitModeProvider>()
                          .refreshFromSettings();
                    }
                  },
          ),
          if (transitModeEnabled)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TransitModeSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Wake timing'),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Start monitoring',
                  enabled: canStart,
                  child: FilledButton.icon(
                    onPressed: canStart
                        ? () => _handleStartMonitoring(context)
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Stop monitoring',
                  enabled: canStop,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        canStop ? () => _handleStopMonitoring(context) : null,
                    icon: const Icon(Icons.stop_rounded, size: 20),
                    label: const Text('Stop'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!hasDestination) ...[
            const SizedBox(height: 12),
            Text(
              'Set a destination before starting monitoring.',
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
      MonitoringState.arrived => colorScheme.tertiary,
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
