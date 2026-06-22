import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/destination.dart';
import '../models/gtfs_feed_info.dart';
import '../models/monitoring_state.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_stop.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../providers/transit_provider.dart';
import '../services/background_monitor_service.dart';
import '../utils/location_format.dart';
import '../utils/monitoring_format.dart';
import '../utils/transit_wake_message.dart';
import '../utils/wake_radius_format.dart';
import '../widgets/app_gradient_background.dart';
import '../widgets/arrival_dialog.dart';
import '../widgets/branded_app_bar_title.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/gtfs_readiness_banner.dart';
import '../widgets/home_card.dart';
import '../widgets/metric_row.dart';
import '../widgets/monitoring_distance_progress.dart';
import '../widgets/transit_route_progress_line.dart';
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
    final isMonitoring = context.select<MonitoringProvider, MonitoringState>(
      (provider) => provider.currentState,
    ) == MonitoringState.monitoring;
    final hasDestination = context.select<MonitoringProvider, bool>(
      (provider) => provider.selectedDestination != null,
    );
    final monitoringFirst = isMonitoring || hasDestination;

    if (arrivalVisible && !_showingArrivalDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_presentArrivalDialog());
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(),
      ),
      body: AppGradientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: monitoringFirst
              ? [
                  const _MonitoringCard(),
                  const SizedBox(height: 16),
                  _DestinationCard(compact: hasDestination),
                  const TripSetupChecklist(),
                  const GtfsReadinessBanner(),
                ]
              : [
                  const _DestinationCard(compact: false),
                  const SizedBox(height: 16),
                  const _MonitoringCard(),
                  const TripSetupChecklist(),
                  const GtfsReadinessBanner(),
                ],
        ),
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

bool _isGtfsReadyForTransitMode(BuildContext context) {
  if (context.read<GtfsProvider>().hasStopsForSelectedLine()) {
    return true;
  }

  final transitSystem =
      context.read<TransitProvider>().preferences.transitSystem;
  if (!TransitCatalog.hasCatalogLines(transitSystem)) {
    return false;
  }

  final feed =
      context.read<GtfsFeedProvider>().feedForTransitSystem(transitSystem);
  return feed?.status == GtfsFeedStatus.downloaded;
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.compact});

  final bool compact;

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
    final gtfsReady = _isGtfsReadyForTransitMode(context);
    final routeSegmentStops = context.select<TransitModeProvider, List<TransitStop>>(
      (provider) => provider.routeSegmentStops,
    );
    final wakeMessage = TransitWakeMessage.forHome(
      transitModeEnabled: transitModeEnabled,
      gtfsReady: gtfsReady,
      snapshot: snapshot,
      isMonitoring: isMonitoring,
      selectedLine: selectedLine,
    );
    final showTransitProgress = destination != null &&
        transitModeEnabled &&
        gtfsReady;
    final idleTransitPrompt = showTransitProgress &&
        !isMonitoring &&
        !snapshot.isActive;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(
            icon: Icons.location_on_outlined,
            title: compact ? 'Your stop' : 'Destination',
            iconColor: colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          if (destination == null)
            const EmptyStateMessage(
              message:
                  'Pick where you want to wake up — a station, address, or map pin.',
            )
          else ...[
            Text(
              destination.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            if (idleTransitPrompt) ...[
              Text(
                'Start monitoring to see stop-by-stop progress.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                selectedLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ] else
              Text(
                wakeMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
          ],
          if (showTransitProgress) ...[
            const SizedBox(height: 16),
            TransitRouteProgressLine(
              isActive: snapshot.isActive,
              stops: routeSegmentStops,
              stopsRemaining: snapshot.stopsRemaining,
              lineLabel: compact ? null : selectedLine,
              inactiveMessage: idleTransitPrompt
                  ? ''
                  : 'Waiting for GPS near your line to place you on the route…',
            ),
            if (snapshot.isActive && snapshot.nextStop != null) ...[
              const SizedBox(height: 8),
              MetricRow(
                label: 'Next stop',
                value: snapshot.nextStop!.stopName,
              ),
            ],
          ],
          if (!isMonitoring) ...[
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: destination == null
                  ? 'Set destination'
                  : 'Change destination',
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => DestinationPickerSheet.show(context),
                  icon: Icon(
                    destination == null
                        ? Icons.add_location_alt_outlined
                        : Icons.edit_location_alt_outlined,
                  ),
                  label: Text(
                    destination == null
                        ? 'Set destination'
                        : 'Change destination',
                  ),
                ),
              ),
            ),
            if (destination != null) ...[
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
    final tripProgress = context.select<LocationProvider, double?>(
      (provider) => provider.tripProgressFraction,
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
      (provider) => provider.transitModeWake.wakeByLabel,
    );
    final wakeSettingLabel = transitModeEnabled
        ? 'Wake by $transitWakeLabel'
        : WakeRadiusFormat.wakeByDescription(radiusMeters);
    final settingsActionLabel =
        transitModeEnabled ? 'Wake Stops' : 'Wake Distance';
    final settingsActionIcon = transitModeEnabled
        ? Icons.tune
        : Icons.radar_outlined;
    final canStart = hasDestination && state == MonitoringState.idle;
    final canStop = state == MonitoringState.monitoring ||
        state == MonitoringState.arrived;
    final isMonitoring = state == MonitoringState.monitoring;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(
            icon: Icons.sensors,
            title: 'Monitoring',
            trailing: hasDestination
                ? TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => transitModeEnabled
                              ? const TransitModeSettingsScreen()
                              : const LocationSettingsScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(settingsActionIcon, size: 18),
                    label: Text(settingsActionLabel),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          MonitoringStatusChip(
            label: 'Status: ${MonitoringFormat.homeStatusLabel(state)}',
            icon: _statusIcon(state),
            color: statusColor,
            active: isMonitoring,
          ),
          const SizedBox(height: 10),
          if (!hasDestination)
            const EmptyStateMessage(
              message: 'Set a destination below, then tap Start to begin monitoring.',
            )
          else if (hasDistance)
            MonitoringDistanceProgress(
              distanceKm: distanceKm,
              progress: tripProgress,
              accentColor: statusColor,
            )
          else
            Text(
              state == MonitoringState.monitoring
                  ? 'Waiting for GPS fix…'
                  : 'Ready when you tap Start',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          MetricRow(label: 'Speed', value: speedLabel),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            secondary: Icon(
              Icons.directions_transit_outlined,
              color: colorScheme.primary,
              size: 22,
            ),
            title: const Text('Transit Mode'),
            subtitle: Text(wakeSettingLabel),
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
          const SizedBox(height: 4),
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
                      minimumSize: const Size(0, 44),
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
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
