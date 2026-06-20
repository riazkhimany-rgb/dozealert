import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/app_permission_snapshot.dart';
import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/transit_data_screen.dart';
import '../services/alarm_service.dart';
import '../services/app_permissions_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/onboarding_permissions_page.dart';
import 'destination_picker_sheet.dart';
import 'home_card.dart';

class TripSetupChecklist extends StatefulWidget {
  const TripSetupChecklist({super.key});

  @override
  State<TripSetupChecklist> createState() => _TripSetupChecklistState();
}

class _TripSetupChecklistState extends State<TripSetupChecklist>
    with WidgetsBindingObserver {
  bool _expanded = true;
  AppPermissionSnapshot? _permissions;
  bool? _alarmTested;
  bool _checksInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checksInitialized) {
      _checksInitialized = true;
      unawaited(_refreshChecks());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshChecks());
    }
  }

  Future<void> _refreshChecks() async {
    try {
      final permissions = context.read<AppPermissionsService>();
      final snapshot = await permissions.snapshot();
      final alarmTested = await OnboardingService().isAlarmTested();
      if (!mounted) {
        return;
      }
      setState(() {
        _permissions = snapshot;
        _alarmTested = alarmTested;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _permissions = null;
        _alarmTested = false;
      });
    }
  }

  Future<void> _openPermissionsSetup() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const _PermissionsSetupScreen(),
      ),
    );
    await _refreshChecks();
  }

  @override
  Widget build(BuildContext context) {
    final permissions = _permissions;
    final hasDestination = context.select<MonitoringProvider, bool>(
      (provider) => provider.selectedDestination != null,
    );
    final transitSystem = context.select<TransitProvider, String>(
      (provider) => provider.preferences.transitSystem,
    );
    final feedProvider = context.watch<GtfsFeedProvider>();

    final needsGtfs = TransitCatalog.hasCatalogLines(transitSystem);
    final gtfsReady = !needsGtfs ||
        (feedProvider.isInitialized &&
            feedProvider.feedForTransitSystem(transitSystem)?.status ==
                GtfsFeedStatus.downloaded);

    final permissionsReady = permissions?.allRequiredForMonitoring ?? false;

    final items = <_ChecklistItem>[
      _ChecklistItem(
        label: 'Destination set',
        complete: hasDestination,
        onTap: () => DestinationPickerSheet.show(context),
      ),
      if (needsGtfs)
        _ChecklistItem(
          label: 'GTFS downloaded',
          complete: gtfsReady,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TransitDataScreen(),
              ),
            );
          },
        ),
      _ChecklistItem(
        label: Platform.isAndroid
            ? 'Permissions (GPS, All the time location, Notifications)'
            : 'Permissions (GPS and location access)',
        complete: permissionsReady,
        onTap: _openPermissionsSetup,
      ),
      _ChecklistItem(
        label: 'Alarm tested',
        complete: _alarmTested ?? false,
        onTap: () async {
          await context.read<AlarmService>().playAlarm();
          await OnboardingService().markAlarmTested();
          await _refreshChecks();
        },
      ),
    ];

    final completeCount = items.where((item) => item.complete).length;
    if (completeCount == items.length) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: HomeCardHeader(
                      icon: Icons.checklist_rtl,
                      title: 'Trip setup ($completeCount/${items.length})',
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.complete
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: item.complete
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  title: Text(item.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: item.onTap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionsSetupScreen extends StatelessWidget {
  const _PermissionsSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip permissions'),
      ),
      body: OnboardingPermissionsPage(
        onStatusChanged: (_) {},
      ),
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.label,
    required this.complete,
    required this.onTap,
  });

  final String label;
  final bool complete;
  final VoidCallback onTap;
}
