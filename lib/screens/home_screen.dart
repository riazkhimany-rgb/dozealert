import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_stop.dart';
import '../providers/monitoring_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/location_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../providers/transit_provider.dart';
import '../services/background_monitor_service.dart';
import '../services/app_tour_service.dart';
import '../utils/app_branding.dart';
import '../utils/location_format.dart';
import '../utils/gtfs_stop_name_utils.dart';
import '../utils/gtfs_readiness.dart';
import '../utils/transit_wake_message.dart';
import '../utils/trip_ux_copy.dart';
import '../utils/wake_radius_format.dart';
import '../screens/map_picker_screen.dart';
import '../widgets/app_gradient_background.dart';
import '../widgets/arrival_dialog.dart';
import '../widgets/branded_app_bar_title.dart';
import '../widgets/home_setup_status_card.dart';
import '../widgets/home_card.dart';
import '../widgets/home_tour.dart';
import '../widgets/metric_row.dart';
import '../widgets/monitoring_distance_progress.dart';
import '../widgets/quick_picks_sheet.dart';
import '../widgets/transit_route_progress_line.dart';
import '../widgets/trip_ready_sheet.dart';
import '../widgets/trip_concern_banner.dart';
import '../widgets/trip_stop_picker_sheet.dart';
import '../widgets/transit_agency_line_picker_sheet.dart';
import '../widgets/watch_connection_indicator.dart';
import '../widgets/wake_alert_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showingArrivalDialog = false;
  bool _homeTourVisible = false;
  bool _startInProgress = false;
  bool _stopInProgress = false;
  AppTourService? _appTourService;
  ShowcaseView? _showcaseView;

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

    final tourService = context.read<AppTourService>();
    final shouldShow =
        tourService.replayRequested || await tourService.shouldShowHomeTour();
    if (!mounted || !shouldShow) {
      return;
    }

    setState(() => _homeTourVisible = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showcaseView?.startShowCase([
        _setDestinationKey,
        _wakeSettingsKey,
        _startMonitoringKey,
      ], delay: const Duration(milliseconds: 300));
    });
  }

  Future<void> _finishHomeTour() async {
    await context.read<AppTourService>().markHomeTourComplete();
    if (mounted) {
      setState(() => _homeTourVisible = false);
    }
  }

  Future<void> _openWakeSettings() async {
    await WakeAlertSheet.show(context);
  }

  List<HomeTourStepContent> _tourStepContents(BuildContext context) {
    final transitModeEnabled = context
        .read<SettingsProvider>()
        .transitModeEnabled;
    final wakeSetting = context.read<SettingsProvider>().transitModeWake;
    if (transitModeEnabled) {
      return [
        const HomeTourStepContent(
          id: HomeTourStepId.setDestination,
          title: TripUxCopy.pickYourStop,
          body:
              'Tap Pick your stop, confirm your transit and line if needed, '
              'then search for the stop where you want to get off.',
        ),
        HomeTourStepContent(
          id: HomeTourStepId.wakeSettings,
          title: TripUxCopy.changeWakeStops,
          body: TripUxCopy.wakeSettingsTourBody(wakeSetting),
        ),
        const HomeTourStepContent(
          id: HomeTourStepId.startMonitoring,
          title: 'Start before you sleep',
          body:
              'Tap Start when you sit down on the bus or train. DozeAlert '
              'tracks your ride and wakes you at the right time.',
        ),
      ];
    }

    return [
      const HomeTourStepContent(
        id: HomeTourStepId.setDestination,
        title: TripUxCopy.pickDestination,
        body:
            'Tap Pick destination, search on the map or drop a pin, '
            'then set it as your destination — great for taxi, Uber, '
            'or any ride where you wake by distance instead of stops.',
      ),
      const HomeTourStepContent(
        id: HomeTourStepId.wakeSettings,
        title: TripUxCopy.changeWakeDistance,
        body:
            'Choose how close to your destination you want to wake up '
            'using your alert distance.',
      ),
      const HomeTourStepContent(
        id: HomeTourStepId.startMonitoring,
        title: 'Start before you sleep',
        body:
            'Tap Start when you are on your way. DozeAlert tracks your '
            'location and wakes you within your alert distance.',
      ),
    ];
  }

  HomeTourCard _tourCard(HomeTourStepId id, List<HomeTourStepContent> steps) {
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
    final tourSteps = _tourStepContents(context);

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
      tourActive: _homeTourVisible,
      setDestinationKey: _setDestinationKey,
      setDestinationTourCard: _tourCard(
        HomeTourStepId.setDestination,
        tourSteps,
      ),
    );
    final monitoringCard = _MonitoringCard(
      tourActive: _homeTourVisible,
      startInProgress: _startInProgress,
      stopInProgress: _stopInProgress,
      wakeSettingsKey: _wakeSettingsKey,
      onOpenWakeSettings: () => unawaited(_openWakeSettings()),
      startMonitoringKey: _startMonitoringKey,
      onStartMonitoring: () => unawaited(_handleStartMonitoring()),
      onStopMonitoring: () => unawaited(_handleStopMonitoring()),
      wakeSettingsTourCard: _tourCard(HomeTourStepId.wakeSettings, tourSteps),
      startMonitoringTourCard: _tourCard(
        HomeTourStepId.startMonitoring,
        tourSteps,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const BrandedAppBarTitle()),
      body: AppGradientBackground(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            destinationCard,
            const SizedBox(height: 16),
            monitoringCard,
            if (!_homeTourVisible) const HomeSetupStatusCard(),
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

  Future<void> _handleStartMonitoring() async {
    if (_startInProgress) {
      return;
    }

    await _handleStartMonitoringForHome(
      context,
      setInProgress: () {
        if (mounted) {
          setState(() => _startInProgress = true);
        }
      },
      clearInProgress: () {
        if (mounted) {
          setState(() => _startInProgress = false);
        }
      },
    );
  }

  Future<void> _handleStopMonitoring() async {
    if (_stopInProgress) {
      return;
    }

    setState(() {
      _startInProgress = false;
      _stopInProgress = true;
    });

    try {
      await context.read<LocationProvider>().stopTracking();
    } finally {
      if (mounted) {
        setState(() => _stopInProgress = false);
      }
    }
  }
}

Future<void> _handleStartMonitoringForHome(
  BuildContext context, {
  required VoidCallback setInProgress,
  required VoidCallback clearInProgress,
}) async {
  if (context.read<MonitoringProvider>().currentState ==
      MonitoringState.missed) {
    context.read<MonitoringProvider>().resetToIdle();
  }

  try {
    final proceed = await TripReadySheet.confirmStart(context);
    if (!proceed || !context.mounted) {
      if (context.mounted && !proceed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Complete the steps above before starting your trip.',
            ),
          ),
        );
      }
      return;
    }

    setInProgress();

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
        onContinueAfterBatteryPrompt:
            result == LocationStartResult.batteryOptimizationRequired
            ? () => tryStart(resume: true)
            : null,
      );
    }

    await tryStart();
  } finally {
    clearInProgress();
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
    required this.tourActive,
    required this.setDestinationKey,
    required this.setDestinationTourCard,
  });

  final bool compact;
  final bool tourActive;
  final GlobalKey setDestinationKey;
  final Widget setDestinationTourCard;

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
    final radiusMeters = context.select<MonitoringProvider, int>(
      (provider) => provider.radiusMeters,
    );
    final routeSegmentStops = context
        .select<TransitModeProvider, List<TransitStop>>(
          (provider) => provider.routeSegmentStops,
        );
    final showConcernBanner =
        isMonitoring && snapshot.isActive && snapshot.hasTripConcern;
    final showTransitProgress =
        destination != null && transitModeEnabled && gtfsReady;
    final pickDestinationLabel = transitModeEnabled
        ? TripUxCopy.pickYourStop
        : TripUxCopy.pickDestination;
    final destinationCardTitle = destination == null
        ? pickDestinationLabel
        : transitModeEnabled
        ? TripUxCopy.yourStop
        : TripUxCopy.yourDestination;
    final transitModeWake = context
        .select<SettingsProvider, TransitModeWakeSetting>(
          (provider) => provider.transitModeWake,
        );
    final clearDestinationLabel = TripUxCopy.clear;
    final changeDestinationLabel = transitModeEnabled
        ? TripUxCopy.changeStop
        : TripUxCopy.changeDestination;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: WatchConnectionIndicatorIfInstalled()),
          HomeCardHeader(
            icon: transitModeEnabled
                ? Icons.location_on_outlined
                : Icons.place_outlined,
            title: destinationCardTitle,
            iconColor: isMonitoring
                ? colorScheme.secondary
                : colorScheme.onSurfaceVariant,
            trailing: destination != null && !isMonitoring
                ? _DestinationActionButton(
                    label: clearDestinationLabel,
                    icon: Icons.close_rounded,
                    onPressed: () =>
                        context.read<MonitoringProvider>().clearDestination(),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          if (destination == null) ...[
            Text(
              transitModeEnabled
                  ? TripUxCopy.emptyHeadline
                  : TripUxCopy.emptyHeadlineDistance,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              transitModeEnabled
                  ? TripUxCopy.emptySubtitleForWake(transitModeWake)
                  : TripUxCopy.emptySubtitleDistance,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ] else ...[
            Text(
              destination.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (transitModeEnabled && selectedLine.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                selectedLine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!isMonitoring && !snapshot.isActive)
              Text(
                transitModeEnabled
                    ? TripUxCopy.wakeTargetLabel(
                        wakeSetting: transitModeWake,
                        destinationName: destination.name,
                        wakeAtStopName: TransitWakeMessage.wakeStopNameFor(
                          snapshot: snapshot,
                          wakeStopCount: transitModeWake.wakeStopCount,
                          segmentStops: routeSegmentStops,
                        ),
                      )
                    : WakeRadiusFormat.wakeByDescription(radiusMeters),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              )
            else if (!transitModeEnabled)
              Text(
                WakeRadiusFormat.wakeByDescription(radiusMeters),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            if (showConcernBanner)
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
              alongRouteRemainingMeters: snapshot.alongRouteRemainingMeters,
              lineLabel: compact ? null : selectedLine,
              nextStopName: snapshot.isActive && snapshot.nextStop != null
                  ? GtfsStopNameUtils.stationDisplayName(
                      snapshot.nextStop!.stopName,
                    )
                  : null,
              inactiveMessage: isMonitoring
                  ? TripUxCopy.confirmingRoute
                  : TripUxCopy.routeProgressBeforeStart,
            ),
            if (transitModeEnabled &&
                !isMonitoring &&
                snapshot.directionLabel != null &&
                snapshot.directionConfirming) ...[
              const SizedBox(height: 8),
              MetricRow(
                label: 'Direction',
                value: '${snapshot.directionLabel!} (confirming…)',
              ),
            ],
          ],
          if (!isMonitoring) ...[
            if (destination == null) ...[
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: pickDestinationLabel,
                child: SizedBox(
                  width: double.infinity,
                  child: tourActive
                      ? _tourTarget(
                          key: setDestinationKey,
                          container: setDestinationTourCard,
                          child: FilledButton.icon(
                            onPressed: () => unawaited(
                              _openPrimaryDestinationPicker(
                                context,
                                transitModeEnabled: transitModeEnabled,
                              ),
                            ),
                            icon: Icon(
                              transitModeEnabled
                                  ? Icons.add_location_alt_outlined
                                  : Icons.map_outlined,
                            ),
                            label: Text(pickDestinationLabel),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () => unawaited(
                            _openPrimaryDestinationPicker(
                              context,
                              transitModeEnabled: transitModeEnabled,
                            ),
                          ),
                          icon: Icon(
                            transitModeEnabled
                                ? Icons.add_location_alt_outlined
                                : Icons.map_outlined,
                          ),
                          label: Text(pickDestinationLabel),
                        ),
                ),
              ),
              if (transitModeEnabled) ...[
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DestinationActionButton(
                            label: TripUxCopy.quickPicksTitle,
                            icon: Icons.bookmarks_outlined,
                            onPressed: () => QuickPicksSheet.show(context),
                          ),
                          _DestinationActionButton(
                            label: TripUxCopy.changeLine,
                            icon: Icons.directions_transit_outlined,
                            onPressed: () => unawaited(
                              TransitAgencyLinePickerSheet.show(context),
                            ),
                          ),
                        ],
                      ),
                      if (selectedLine.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          selectedLine,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Center(
                  child: _DestinationActionButton(
                    label: TripUxCopy.quickPicksTitle,
                    icon: Icons.bookmarks_outlined,
                    onPressed: () => QuickPicksSheet.show(context),
                  ),
                ),
              ],
            ] else ...[
              const SizedBox(height: 12),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _DestinationActionButton(
                          label: changeDestinationLabel,
                          icon: transitModeEnabled
                              ? Icons.edit_location_alt_outlined
                              : Icons.map_outlined,
                          onPressed: () => unawaited(
                            _openPrimaryDestinationPicker(
                              context,
                              transitModeEnabled: transitModeEnabled,
                            ),
                          ),
                        ),
                        if (transitModeEnabled)
                          _DestinationActionButton(
                            label: TripUxCopy.changeLine,
                            icon: Icons.directions_transit_outlined,
                            onPressed: () => unawaited(
                              TransitAgencyLinePickerSheet.show(context),
                            ),
                          )
                        else
                          _DestinationActionButton(
                            label: TripUxCopy.quickPicksTitle,
                            icon: Icons.bookmarks_outlined,
                            onPressed: () => QuickPicksSheet.show(context),
                          ),
                      ],
                    ),
                    if (transitModeEnabled) ...[
                      const SizedBox(height: 12),
                      _DestinationActionButton(
                        label: TripUxCopy.quickPicksTitle,
                        icon: Icons.bookmarks_outlined,
                        onPressed: () => QuickPicksSheet.show(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

Future<void> _openPrimaryDestinationPicker(
  BuildContext context, {
  required bool transitModeEnabled,
}) async {
  if (transitModeEnabled) {
    await TripStopPickerSheet.show(context);
    return;
  }

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => const MapPickerScreen(),
    ),
  );
}

String _compactWakeSettingLabel(TransitModeWakeSetting setting) {
  return switch (setting) {
    TransitModeWakeSetting.atDestination => 'At destination',
    TransitModeWakeSetting.oneStopBefore => '1 stop before',
    TransitModeWakeSetting.twoStopsBefore => '2 stops before',
  };
}

class _DestinationActionButton extends StatelessWidget {
  const _DestinationActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _WakeSettingControl extends StatelessWidget {
  const _WakeSettingControl({
    required this.transitModeEnabled,
    required this.wakeSettingLabel,
    required this.onOpenWakeSettings,
  });

  final bool transitModeEnabled;
  final String wakeSettingLabel;
  final VoidCallback onOpenWakeSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonIcon = transitModeEnabled
        ? Icons.notifications_active_outlined
        : Icons.straighten_outlined;
    final secondLine = transitModeEnabled ? 'alert stops' : 'alert distance';
    final labelStyle = Theme.of(context).textTheme.labelMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: onOpenWakeSettings,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(buttonIcon, size: 16),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Change', style: labelStyle),
                  Text(secondLine, style: labelStyle),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          wakeSettingLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StartTripButton extends StatelessWidget {
  const _StartTripButton({required this.inProgress, required this.onPressed});

  final bool inProgress;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: inProgress ? null : onPressed,
      icon: inProgress
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.play_arrow_rounded, size: 22),
      label: Text(inProgress ? TripUxCopy.startingTrip : TripUxCopy.startTrip),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}

class _MonitoringCard extends StatelessWidget {
  const _MonitoringCard({
    required this.tourActive,
    required this.startInProgress,
    required this.stopInProgress,
    required this.wakeSettingsKey,
    required this.onOpenWakeSettings,
    required this.startMonitoringKey,
    required this.onStartMonitoring,
    required this.onStopMonitoring,
    required this.wakeSettingsTourCard,
    required this.startMonitoringTourCard,
  });

  final bool tourActive;
  final bool startInProgress;
  final bool stopInProgress;
  final GlobalKey wakeSettingsKey;
  final VoidCallback onOpenWakeSettings;
  final GlobalKey startMonitoringKey;
  final VoidCallback onStartMonitoring;
  final VoidCallback onStopMonitoring;
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
    final establishingGps = context.select<LocationProvider, bool>(
      (provider) => provider.establishingGps,
    );
    final gpsPrewarming = context.select<LocationProvider, bool>(
      (provider) => provider.gpsPrewarming,
    );
    final statusColor = _statusColor(colorScheme, state);
    final transitModeEnabled = context.select<SettingsProvider, bool>(
      (provider) => provider.transitModeEnabled,
    );
    final transitWakeSetting = context
        .select<SettingsProvider, TransitModeWakeSetting>(
          (provider) => provider.transitModeWake,
        );
    final compactWakeLabel = transitModeEnabled
        ? _compactWakeSettingLabel(transitWakeSetting)
        : WakeRadiusFormat.wakeByDescription(radiusMeters);
    final distanceStale = distanceIsStale || gpsSignalLost;
    final distanceSubtitle = distanceStale
        ? '${TripUxCopy.staleDistanceSubtitle} — ${TripUxCopy.gpsSignalWeakBase}'
        : null;
    final distanceInlineNote = !distanceStale && usingAlongRoute
        ? 'along route'
        : null;
    final canStart =
        hasDestination &&
        (state == MonitoringState.idle || state == MonitoringState.missed);
    final canStop =
        state == MonitoringState.monitoring || state == MonitoringState.arrived;
    final isMonitoring = state == MonitoringState.monitoring;
    final tripIconTint = isMonitoring
        ? colorScheme.secondary
        : colorScheme.onSurfaceVariant;
    final showLockPhoneHint =
        isMonitoring && !establishingGps && !gpsPrewarming && !gpsSignalLost;
    final monitoringGpsStatus = TripUxCopy.gpsStatusLabel(
      establishingGps: establishingGps,
      gpsPrewarming: gpsPrewarming,
      gpsSignalLost: gpsSignalLost,
    );

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tripIconTint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.sensors, color: tripIconTint, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: isMonitoring
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  TripUxCopy.watchingTripLine1,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                ),
                                Text(
                                  TripUxCopy.watchingTripLine2,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.25,
                                      ),
                                ),
                              ],
                            )
                          : Text(
                              'Your trip',
                              maxLines: 2,
                              softWrap: true,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    tourActive
                        ? _tourTarget(
                            key: wakeSettingsKey,
                            container: wakeSettingsTourCard,
                            child: _WakeSettingControl(
                              transitModeEnabled: transitModeEnabled,
                              wakeSettingLabel: compactWakeLabel,
                              onOpenWakeSettings: onOpenWakeSettings,
                            ),
                          )
                        : _WakeSettingControl(
                            transitModeEnabled: transitModeEnabled,
                            wakeSettingLabel: compactWakeLabel,
                            onOpenWakeSettings: onOpenWakeSettings,
                          ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasDestination)
            Text(
              TripUxCopy.readyWhenYouAre,
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
          else if (!hasDistance && isMonitoring)
            Text(
              'Waiting for GPS fix…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (!isMonitoring)
            Text(
              TripUxCopy.startWhenOnBoard,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (isMonitoring &&
              monitoringGpsStatus != TripUxCopy.lockPhoneHint) ...[
            const SizedBox(height: 8),
            Text(
              monitoringGpsStatus,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if ((canStart || tourActive) && !stopInProgress)
            Semantics(
              button: true,
              label: 'Start trip',
              enabled: canStart,
              child: tourActive
                  ? _tourTarget(
                      key: startMonitoringKey,
                      container: startMonitoringTourCard,
                      child: _StartTripButton(
                        inProgress: startInProgress && !isMonitoring,
                        onPressed: canStart ? onStartMonitoring : null,
                      ),
                    )
                  : _StartTripButton(
                      inProgress: startInProgress && !isMonitoring,
                      onPressed: onStartMonitoring,
                    ),
            ),
          if (canStop || stopInProgress) ...[
            Semantics(
              button: true,
              label: 'Stop trip',
              child: OutlinedButton.icon(
                onPressed: stopInProgress ? null : onStopMonitoring,
                icon: stopInProgress
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.stop_rounded, size: 20),
                label: Text(
                  stopInProgress
                      ? TripUxCopy.stoppingTrip
                      : TripUxCopy.stopTrip,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            if (showLockPhoneHint) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  TripUxCopy.lockPhoneHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme colorScheme, MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => colorScheme.onSurfaceVariant,
      MonitoringState.monitoring => colorScheme.primary,
      MonitoringState.arrived => colorScheme.tertiary,
      MonitoringState.missed => colorScheme.error,
    };
  }
}
