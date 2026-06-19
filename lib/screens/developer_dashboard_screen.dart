import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/developer_diagnostics_snapshot.dart';
import '../models/trip_history_entry.dart';
import '../providers/location_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_mode_provider.dart';
import '../services/developer_diagnostics_service.dart';
import '../utils/location_format.dart';
import '../widgets/home_card.dart';

class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  State<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  DeveloperDiagnosticsSnapshot? _snapshot;
  bool _loading = false;
  bool _exporting = false;
  bool _hasLoaded = false;

  Future<void> _refreshSnapshot() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final diagnosticsService = context.read<DeveloperDiagnosticsService>();
      final snapshot = await diagnosticsService.collectSnapshot(
        locationProvider: context.read<LocationProvider>(),
        monitoringProvider: context.read<MonitoringProvider>(),
        transitModeProvider: context.read<TransitModeProvider>(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _snapshot = snapshot;
        _hasLoaded = true;
      });
    } catch (error) {
      debugPrint('DeveloperDashboardScreen: refresh failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportDiagnostics() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    setState(() {
      _exporting = true;
    });

    try {
      final file = await context
          .read<DeveloperDiagnosticsService>()
          .exportDiagnosticsJson(snapshot: snapshot);
      final contents = await file.readAsString();
      await Clipboard.setData(ClipboardData(text: contents));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported diagnostics.json to ${file.path} (copied to clipboard)',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refreshSnapshot,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !_hasLoaded && !_loading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.dashboard_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Load live diagnostics for beta testing.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _refreshSnapshot,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Load Dashboard'),
                    ),
                  ],
                ),
              ),
            )
          : _loading && snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshSnapshot,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (snapshot != null) ...[
                    _StatusCard(snapshot: snapshot),
                    const SizedBox(height: 16),
                    _ActionButtons(
                      onRefreshComplete: _refreshSnapshot,
                    ),
                    const SizedBox(height: 16),
                    _TripHistoryCard(
                      entries: snapshot.tripHistory,
                      onRefresh: _refreshSnapshot,
                    ),
                    const SizedBox(height: 16),
                    _DiagnosticsCard(snapshot: snapshot),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _exporting ? null : _exportDiagnostics,
                        icon: _exporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_outlined),
                        label: Text(
                          _exporting
                              ? 'Exporting…'
                              : 'Export diagnostics.json',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});

  final DeveloperDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.dashboard_outlined,
            title: 'Live Status',
          ),
          const SizedBox(height: 12),
          _MetricRow(label: 'Current Location', value: snapshot.currentLocation),
          _MetricRow(label: 'Current Stop', value: snapshot.currentStation),
          _MetricRow(label: 'Next Stop', value: snapshot.nextStation),
          _MetricRow(label: 'Destination', value: snapshot.destination),
          _MetricRow(
            label: 'Stops Remaining',
            value: '${snapshot.stationsRemaining}',
          ),
          _MetricRow(
            label: 'Distance Remaining',
            value: snapshot.destination == '—'
                ? '—'
                : '${snapshot.distanceRemainingKm.toStringAsFixed(1)} km',
          ),
          _MetricRow(label: 'Speed', value: snapshot.speedKmh),
          _MetricRow(
            label: 'Monitoring Status',
            value: snapshot.monitoringStatus,
          ),
          _MetricRow(
            label: 'Alarm Status',
            value: snapshot.alarmActive ? 'Active' : 'Idle',
          ),
          _MetricRow(
            label: 'Foreground Service Running',
            value: snapshot.foregroundServiceRunning ? 'Yes' : 'No',
          ),
          _MetricRow(
            label: 'Battery Optimization Disabled',
            value: snapshot.batteryOptimizationDisabled ? 'Yes' : 'No',
          ),
          _MetricRow(label: 'Last GPS Update', value: snapshot.lastGpsUpdate),
          _MetricRow(
            label: 'Notification Permission',
            value: snapshot.notificationPermissionGranted ? 'Granted' : 'Denied',
          ),
          _MetricRow(
            label: 'Location Permission',
            value: snapshot.locationPermissionGranted ? 'Granted' : 'Denied',
          ),
          _MetricRow(
            label: 'Last Alarm Time',
            value: snapshot.lastAlarmTriggered,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onRefreshComplete});

  final Future<void> Function() onRefreshComplete;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.play_circle_outline,
            title: 'Developer Actions',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () async {
                  await context.read<LocationProvider>().developerTriggerAlarm();
                  await onRefreshComplete();
                },
                child: const Text('Trigger Alarm'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await context.read<LocationProvider>().developerStopAlarm();
                  await onRefreshComplete();
                },
                child: const Text('Stop Alarm'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  context
                      .read<LocationProvider>()
                      .developerSimulateOneStopRemaining();
                  onRefreshComplete();
                },
                child: const Text('Simulate One Stop Remaining'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await context.read<LocationProvider>().developerSimulateArrival();
                  await onRefreshComplete();
                },
                child: const Text('Simulate Arrival'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await context.read<LocationProvider>().refreshLocation();
                  await onRefreshComplete();
                },
                child: const Text('Refresh Location'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({
    required this.entries,
    required this.onRefresh,
  });

  final List<TripHistoryEntry> entries;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeCardHeader(
            icon: Icons.history,
            title: 'Trip History',
            trailing: IconButton(
              tooltip: 'Reload history',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              'No trip history recorded yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...entries.take(10).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.destination,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _MetricRow(
                      label: 'Trip Start',
                      value: _formatTime(entry.tripStart),
                    ),
                    _MetricRow(
                      label: 'Trip End',
                      value: _formatTime(entry.tripEnd),
                    ),
                    _MetricRow(
                      label: 'Alarm Triggered',
                      value: _formatTime(entry.alarmTriggered),
                    ),
                    _MetricRow(
                      label: 'Alarm Dismissed',
                      value: _formatTime(entry.alarmDismissed),
                    ),
                    _MetricRow(
                      label: 'Missed Trip',
                      value: entry.missedTrip ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return '—';
    }
    return LocationFormat.lastUpdated(time);
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.snapshot});

  final DeveloperDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeCardHeader(
            icon: Icons.health_and_safety_outlined,
            title: 'Diagnostics',
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'GPS Enabled',
            value: snapshot.gpsEnabled ? 'Yes' : 'No',
          ),
          _MetricRow(
            label: 'Location Permission',
            value: snapshot.locationPermissionGranted ? 'Granted' : 'Denied',
          ),
          _MetricRow(
            label: 'Background Location Permission',
            value: snapshot.backgroundLocationPermissionGranted
                ? 'Granted'
                : 'Denied',
          ),
          _MetricRow(
            label: 'Notification Permission',
            value: snapshot.notificationPermissionGranted ? 'Granted' : 'Denied',
          ),
          _MetricRow(
            label: 'Foreground Service',
            value: snapshot.foregroundServiceRunning ? 'Running' : 'Stopped',
          ),
          _MetricRow(
            label: 'Background Monitoring',
            value: snapshot.backgroundMonitoringEnabled ? 'Active' : 'Inactive',
          ),
          _MetricRow(
            label: 'Battery Optimization Disabled',
            value: snapshot.batteryOptimizationDisabled ? 'Yes' : 'No',
          ),
          _MetricRow(
            label: 'Last Alarm Dismissed',
            value: snapshot.lastAlarmDismissed,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
