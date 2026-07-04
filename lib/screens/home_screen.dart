import 'dart:async';
import 'dart:io';

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
import '../providers/wear_status_provider.dart';
import '../services/background_monitor_service.dart';
import '../services/app_tour_service.dart';
import '../utils/app_branding.dart';
import '../utils/location_format.dart';
import '../utils/monitoring_format.dart';
import '../utils/gtfs_stop_name_utils.dart';
import '../utils/gtfs_readiness.dart';
import '../utils/transit_user_copy.dart';
import '../utils/transit_wake_message.dart';
import '../utils/trip_ux_copy.dart';
import '../utils/wake_radius_format.dart';
import '../widgets/app_gradient_background.dart';
import '../widgets/arrival_dialog.dart';
import '../widgets/branded_app_bar_title.dart';
import '../widgets/trip_stop_picker_sheet.dart';
import '../widgets/gtfs_readiness_banner.dart';
import '../widgets/home_card.dart';
import '../widgets/home_tour.dart';
import '../widgets/metric_row.dart';
import '../widgets/monitoring_distance_progress.dart';
import '../widgets/transit_route_progress_line.dart';
import '../widgets/trip_ready_sheet.dart';
import '../widgets/gtfs_updating_banner.dart';
import '../widgets/trip_concern_banner.dart';
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

    final shouldShow = context.read<AppTourService>().replayRequested;
    if (!mounted || !shouldShow) {
      return;
    }

    setState(() => _homeTourVisible = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showcaseView?.startShowCase(
        [
          _setDestinationKey,
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
            title: TransitUserCopy.homeTourConfirmTransitTitle,
            body: TransitUserCopy.homeTourConfirmTransitBody,
          ),
        const HomeTourStepContent(
          id: HomeTourStepId.setDestination,
          title: TripUxCopy.pickYourStop,
          body:
              'Tap Pick your stop, choose your route if needed, then search '
              'for the station where you want to get off.',
        ),
        const HomeTourStepContent(
          id: HomeTourStepId.startMonitoring,
          title: 'Start before you sleep',
          body:
              'Tap Start when you sit down on the bus or train. DozeAlert '
              'wakes you one stop before your stop by default.',
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
    final hasDestination = context.select<MonitoringProvider, bool>(
      (provider) => provider.selectedDestination != null,
    );
    final transitModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final tourSteps = _tourStepContents(transitModeEnabled);

    if (arrivalVisible && !_showingArrivalDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_presentArrivalDialog());
      });
    }

    if (!arrivalVisible && _showingArrivalDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_showingArrivalDialog) {
          return;
        }
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (mounted) {
          setState(() => _showingArrivalDialog = false);
        }
      });
    }

    final destinationCard = _DestinationCard(
      compact: hasDestination,
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
            destinationCard,
            const SizedBox(height: 16),
            monitoringCard,
            if (!_homeTourVisible) ...[
              const TripSetupChecklist(),
              const GtfsUpdatingBanner(),
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
    final showConcernBanner = isMonitoring &&
        snapshot.isActive &&
        snapshot.hasTripConcern;
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
            title: compact
                ? TripUxCopy.yourStop
                : (destination == null
                    ? TripUxCopy.pickYourStop
                    : TripUxCopy.readyWhenYouAre),
            iconColor: colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          if (destination == null) ...[
            Text(
              TripUxCopy.emptyHeadline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              TripUxCopy.emptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
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
            if (transitModeEnabled && selectedLine.isNotEmpty) ...[
              Text(
                selectedLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              destination.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            if (!isMonitoring)
              Text(
                TripUxCopy.wakeTargetLabel(
                  wakeSetting:
                      context.read<SettingsProvider>().transitModeWake,
                  destinationName: destination.name,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              )
            else if (idleTransitPrompt) ...[
              Text(
                'Start your trip to see stop-by-stop progress.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ] else if (!showConcernBanner)
              Text(
                wakeMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            TripConcernBanner(
              snapshot: snapshot,
              selectedLine: selectedLine,
              gpsSignalLost: gpsSignalLost,
              transitModeEnabled: transitModeEnabled,
              gtfsReady: gtfsReady,
              isMonitoring: isMonitoring,
            ),
          ],
          if (showTransitProgress) ...[
            const SizedBox(height: 16),
            TransitRouteProgressLine(
              isActive: snapshot.isActive,
              stops: routeSegmentStops,
              stopsRemaining: snapshot.stopsRemaining,
              lineLabel: compact ? null : selectedLine,
              nextStopName: snapshot.isActive && snapshot.nextStop != null
                  ? GtfsStopNameUtils.stationDisplayName(
                      snapshot.nextStop!.stopName,
                    )
                  : null,
              inactiveMessage: '',
            ),
            if (transitModeEnabled &&
                snapshot.directionLabel != null &&
                (isMonitoring || snapshot.directionConfirming)) ...[
              const SizedBox(height: 8),
              MetricRow(
                label: 'Direction',
                value: snapshot.directionConfirming
                    ? '${snapshot.directionLabel!} (confirming…)'
                    : snapshot.directionLabel!,
              ),
            ],
            if (isMonitoring) ...[
              const SizedBox(height: 4),
              Text(
                _gpsFixLabel(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: gpsSignalLost
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ],
          if (!isMonitoring) ...[
            if (destination == null) ...[
              Semantics(
                button: true,
                label: TripUxCopy.pickYourStop,
                child: SizedBox(
                  width: double.infinity,
                  child: _tourTarget(
                    key: setDestinationKey,
                    container: setDestinationTourCard,
                    child: FilledButton.icon(
                      onPressed: () => TripStopPickerSheet.show(context),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text(TripUxCopy.pickYourStop),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => TripStopPickerSheet.show(context),
                    child: const Text(TripUxCopy.changeStop),
                  ),
                  if (transitModeEnabled)
                    TextButton(
                      onPressed: onChooseAgency,
                      child: const Text(TripUxCopy.changeLine),
                    ),
                  TextButton(
                    onPressed: () =>
                        context.read<MonitoringProvider>().clearDestination(),
                    child: const Text(TripUxCopy.clearStop),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _gpsFixLabel(BuildContext context) {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.establishingGps) {
      return TripUxCopy.findingLocation;
    }
    if (locationProvider.gpsPrewarming) {
      return TripUxCopy.findingLocation;
    }

    final fixAt = locationProvider.lastLocationFixAt;
    if (fixAt == null) {
      return TripUxCopy.findingLocation;
    }
    return TripUxCopy.lockPhoneHint;
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
    final distanceStale = distanceIsStale || gpsSignalLost;
    final distanceSubtitle =
        distanceStale ? 'Last known distance — GPS signal weak' : null;
    final distanceInlineNote =
        !distanceStale && usingAlongRoute ? 'along route' : null;
    final canStart = hasDestination && state == MonitoringState.idle;
    final canStop = state == MonitoringState.monitoring ||
        state == MonitoringState.arrived;
    final isMonitoring = state == MonitoringState.monitoring;
    final watchConnected = Platform.isAndroid
        ? context.select<WearStatusProvider, bool>(
            (provider) => provider.watchConnected,
          )
        : false;
    final watchAppInstalled = Platform.isAndroid
        ? context.select<WearStatusProvider, bool>(
            (provider) => provider.appInstalled,
          )
        : false;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(
            icon: Icons.sensors,
            title: isMonitoring ? TripUxCopy.watchingTrip : 'Your trip',
          ),
          const SizedBox(height: 10),
          if (isMonitoring)
            MonitoringStatusChip(
              label: MonitoringFormat.homeStatusLabel(state),
              icon: _statusIcon(state),
              color: statusColor,
              active: true,
            ),
          if (Platform.isAndroid && watchAppInstalled && isMonitoring) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: watchConnected
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30),
                  ),
                ),
                Text(
                  watchConnected ? 'Watch Connected' : 'Watch Not Connected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: watchConnected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (!hasDestination)
            Text(
              TripUxCopy.emptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            )
          else if (hasDistance)
            MonitoringDistanceProgress(
              distanceKm: distanceKm,
              progress: tripProgress,
              accentColor: statusColor,
              subtitle: distanceSubtitle,
              inlineNote: distanceInlineNote,
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
              TripUxCopy.readyWhenYouAre,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (hasDestination && !isMonitoring) ...[
            const SizedBox(height: 8),
            Text(
              transitModeEnabled
                  ? TripUxCopy.defaultWakeSummary(
                      context.read<SettingsProvider>().transitModeWake,
                    )
                  : wakeSettingLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (isMonitoring) ...[
            const SizedBox(height: 8),
            Text(
              TripUxCopy.gpsStatusLabel(
                establishingGps:
                    context.read<LocationProvider>().establishingGps,
                gpsPrewarming: context.read<LocationProvider>().gpsPrewarming,
                gpsSignalLost: gpsSignalLost,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (canStart)
            Semantics(
              button: true,
              label: 'Start trip',
              child: _tourTarget(
                key: startMonitoringKey,
                container: startMonitoringTourCard,
                child: FilledButton.icon(
                  onPressed: () => _handleStartMonitoring(context),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(TripUxCopy.startTrip),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
          if (canStop)
            Semantics(
              button: true,
              label: 'Stop trip',
              child: OutlinedButton.icon(
                onPressed: () => _handleStopMonitoring(context),
                icon: const Icon(Icons.stop_rounded, size: 20),
                label: const Text(TripUxCopy.stopTrip),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleStartMonitoring(BuildContext context) async {
    final proceed = await TripReadySheet.confirmStart(context);
    if (!proceed || !context.mounted) {
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    final backgroundMonitorService = context.read<BackgroundMonitorService>();

    Future<void> tryStart({bool resume = false}) async {
      final result = await locationProvider.startTracking(resume: resume);
      if (!context.mounted) {
        return;
      }

      if (result == LocationStartResult.success && context.mounted) {
        await TripReadySheet.markTripStarted(context);
      }

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
