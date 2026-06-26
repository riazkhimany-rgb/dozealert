import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_stop.dart';
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../providers/transit_provider.dart';
import '../services/background_monitor_service.dart';
import '../services/app_tour_service.dart';
import '../utils/app_branding.dart';
import '../utils/location_format.dart';
import '../utils/monitoring_format.dart';
import '../utils/gtfs_readiness.dart';
import '../utils/transit_wake_message.dart';
import '../utils/wake_radius_format.dart';
import '../widgets/app_gradient_background.dart';
import '../widgets/arrival_dialog.dart';
import '../widgets/branded_app_bar_title.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/gtfs_readiness_banner.dart';
import '../widgets/home_card.dart';
import '../widgets/home_tour.dart';
import '../widgets/metric_row.dart';
import '../widgets/monitoring_distance_progress.dart';
import '../widgets/transit_route_progress_line.dart';
import '../widgets/trip_setup_checklist.dart';
import '../screens/settings/location_settings_screen.dart';
import '../widgets/transit_agency_line_picker_sheet.dart';
import '../screens/settings/transit_mode_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showingArrivalDialog = false;
  bool _homeTourVisible = false;
  AppTourService? _appTourService;
  ShowcaseView? _showcaseView;

  final _chooseAgencyKey = GlobalKey();
  final _setDestinationKey = GlobalKey();
  final _wakeSettingsKey = GlobalKey();
  final _startMonitoringKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(
      onFinish: () => unawaited(_finishHomeTour()),
      onDismiss: (_) => unawaited(_finishHomeTour()),
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 450),
      disableBarrierInteraction: true,
      disableMovingAnimation: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _appTourService = context.read<AppTourService>();
      _appTourService!.addListener(_handleTourRequest);
      unawaited(_maybeStartHomeTour());
    });
  }

  @override
  void dispose() {
    _appTourService?.removeListener(_handleTourRequest);
    _showcaseView?.unregister();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTourRequest() {
    unawaited(_maybeStartHomeTour());
  }

  Future<void> _maybeStartHomeTour() async {
    if (!mounted || _homeTourVisible) {
      return;
    }

    final shouldShow = await context.read<AppTourService>().shouldShowHomeTour();
    if (!mounted || !shouldShow) {
      return;
    }

    final transitModeEnabled =
        context.read<SettingsProvider>().transitModeEnabled;

    setState(() => _homeTourVisible = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showcaseView?.startShowCase(
        [
          if (transitModeEnabled) _chooseAgencyKey,
          _setDestinationKey,
          _wakeSettingsKey,
          _startMonitoringKey,
        ],
        delay: const Duration(milliseconds: 300),
      );
    });
  }

  Future<void> _finishHomeTour() async {
    await context.read<AppTourService>().markHomeTourComplete();
    if (mounted) {
      setState(() => _homeTourVisible = false);
    }
  }

  Future<void> _openAgencyLinePicker() async {
    await TransitAgencyLinePickerSheet.show(context);
  }

  Future<void> _openWakeSettings() async {
    final transitModeEnabled = context.read<SettingsProvider>().transitModeEnabled;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => transitModeEnabled
            ? const TransitModeSettingsScreen()
            : const LocationSettingsScreen(),
      ),
    );
  }

  List<HomeTourStepContent> _tourStepContents(bool transitModeEnabled) => [
        if (transitModeEnabled)
          const HomeTourStepContent(
            id: HomeTourStepId.chooseAgency,
            title: 'Choose your agency & line',
            body:
                'Pick the transit agency and default line you ride most often. '
                'You can filter by vehicle type and search route numbers.',
          ),
        const HomeTourStepContent(
          id: HomeTourStepId.setDestination,
          title: 'Set your destination',
          body:
              'Choose a stop, search the map, or pick a saved favorite — '
              'DozeAlert wakes you before you arrive.',
        ),
        const HomeTourStepContent(
          id: HomeTourStepId.wakeSettings,
          title: 'Choose when to wake',
          body:
              'Open Wake Stops to set how many stops before yours the alarm '
              'should sound.',
        ),
        const HomeTourStepContent(
          id: HomeTourStepId.startMonitoring,
          title: 'Start your trip',
          body:
              'When you are ready, tap Start. DozeAlert tracks your journey '
              'and wakes you in time.',
        ),
      ];

  HomeTourCard _tourCard(
    HomeTourStepId id,
    List<HomeTourStepContent> steps,
  ) {
    final index = steps.indexWhere((step) => step.id == id);
    final content = index >= 0 ? steps[index] : null;
    return HomeTourCard(
      title: content?.title ?? '',
      body: content?.body ?? '',
      stepIndex: index < 0 ? 0 : index,
      stepCount: steps.length,
      onNext: () => _showcaseView?.next(),
      onBack: index <= 0 ? null : () => _showcaseView?.previous(),
      onSkip: () => _showcaseView?.dismiss(),
    );
  }

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
    final transitModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final monitoringFirst = !_homeTourVisible &&
        (isMonitoring || hasDestination);
    final tourSteps = _tourStepContents(transitModeEnabled);

    if (arrivalVisible && !_showingArrivalDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_presentArrivalDialog());
      });
    }

    final destinationCard = _DestinationCard(
      compact: !monitoringFirst ? false : hasDestination,
      setDestinationKey: _setDestinationKey,
      chooseAgencyKey: _chooseAgencyKey,
      onChooseAgency: () => unawaited(_openAgencyLinePicker()),
      setDestinationTourCard: _tourCard(HomeTourStepId.setDestination, tourSteps),
      chooseAgencyTourCard: _tourCard(HomeTourStepId.chooseAgency, tourSteps),
    );
    final monitoringCard = _MonitoringCard(
      wakeSettingsKey: _wakeSettingsKey,
      onOpenWakeSettings: () => unawaited(_openWakeSettings()),
      startMonitoringKey: _startMonitoringKey,
      wakeSettingsTourCard: _tourCard(HomeTourStepId.wakeSettings, tourSteps),
      startMonitoringTourCard:
          _tourCard(HomeTourStepId.startMonitoring, tourSteps),
    );

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(),
      ),
      body: AppGradientBackground(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (monitoringFirst) ...[
              monitoringCard,
              const SizedBox(height: 16),
              destinationCard,
            ] else ...[
              destinationCard,
              const SizedBox(height: 16),
              monitoringCard,
            ],
            if (!_homeTourVisible) ...[
              const TripSetupChecklist(),
              const GtfsReadinessBanner(),
            ],
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
  return GtfsReadiness.isReadyForSelectedAgency(
    context.read<GtfsProvider>(),
    context.read<TransitProvider>().preferences,
  );
}

/// Wraps a Home control as a guided-tour target with the branded tooltip card.
Widget _tourTarget({
  required GlobalKey key,
  required Widget container,
  required Widget child,
}) {
  return Showcase.withWidget(
    key: key,
    container: container,
    overlayColor: Colors.black,
    overlayOpacity: 0.82,
    targetPadding: const EdgeInsets.all(6),
    targetShapeBorder: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppBranding.cyanAccent, width: 2),
    ),
    child: child,
  );
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.compact,
    required this.setDestinationKey,
    required this.chooseAgencyKey,
    required this.onChooseAgency,
    required this.setDestinationTourCard,
    required this.chooseAgencyTourCard,
  });

  final bool compact;
  final GlobalKey setDestinationKey;
  final GlobalKey chooseAgencyKey;
  final VoidCallback onChooseAgency;
  final Widget setDestinationTourCard;
  final Widget chooseAgencyTourCard;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final destination = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );
    final snapshot = context.select<TransitModeProvider, TransitModeSnapshot>(
      (provider) => provider.displaySnapshot,
    );
    final gpsSignalLost = context.select<TransitModeProvider, bool>(
      (provider) => provider.gpsSignalLost,
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
      gpsSignalLost: gpsSignalLost,
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
          if (destination == null) ...[
            const EmptyStateMessage(
              message:
                  'Pick where you want to wake up — a station, address, or map pin.',
            ),
            if (transitModeEnabled) ...[
              const SizedBox(height: 12),
              Text(
                selectedLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ] else ...[
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
              inactiveMessage: '',
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
            Semantics(
              button: true,
              label: destination == null
                  ? 'Set destination'
                  : 'Change destination',
              child: SizedBox(
                width: double.infinity,
                child: _tourTarget(
                  key: setDestinationKey,
                  container: setDestinationTourCard,
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
            if (transitModeEnabled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _tourTarget(
                  key: chooseAgencyKey,
                  container: chooseAgencyTourCard,
                  child: OutlinedButton.icon(
                    onPressed: onChooseAgency,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Choose agency & line'),
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
  const _MonitoringCard({
    required this.wakeSettingsKey,
    required this.onOpenWakeSettings,
    required this.startMonitoringKey,
    required this.wakeSettingsTourCard,
    required this.startMonitoringTourCard,
  });

  final GlobalKey wakeSettingsKey;
  final VoidCallback onOpenWakeSettings;
  final GlobalKey startMonitoringKey;
  final Widget wakeSettingsTourCard;
  final Widget startMonitoringTourCard;

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
    final distanceIsStale = context.select<LocationProvider, bool>(
      (provider) => provider.distanceIsStale,
    );
    final usingAlongRoute = context.select<LocationProvider, bool>(
      (provider) => provider.usingAlongRouteDistance,
    );
    final gpsSignalLost = context.select<TransitModeProvider, bool>(
      (provider) => provider.gpsSignalLost,
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
    final distanceSubtitle = distanceIsStale || gpsSignalLost
        ? 'Last known distance — GPS signal weak'
        : usingAlongRoute
            ? 'Along route'
            : null;
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
            trailing: _tourTarget(
              key: wakeSettingsKey,
              container: wakeSettingsTourCard,
              child: TextButton.icon(
                onPressed: onOpenWakeSettings,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                icon: Icon(settingsActionIcon, size: 18),
                label: Text(settingsActionLabel),
              ),
            ),
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
              message: 'Set a destination, then tap Start to begin monitoring.',
            )
          else if (hasDistance)
            MonitoringDistanceProgress(
              distanceKm: distanceKm,
              progress: tripProgress,
              accentColor: statusColor,
              subtitle: distanceSubtitle,
            )
          else if (!hasDistance && isMonitoring && !transitModeEnabled)
            Text(
              'Waiting for GPS fix…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (!isMonitoring)
            Text(
              'Ready when you tap Start',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            secondary: Icon(
              Icons.directions_transit_outlined,
              color: colorScheme.primary,
              size: 22,
            ),
            title: const Text('Transit Mode'),
            subtitle: Text(
              transitModeEnabled
                  ? wakeSettingLabel
                  : 'Off — uses wake distance',
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
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Start monitoring',
                  enabled: canStart,
                  child: _tourTarget(
                    key: startMonitoringKey,
                    container: startMonitoringTourCard,
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
