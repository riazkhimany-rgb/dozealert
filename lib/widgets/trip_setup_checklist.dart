import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_provider.dart';
import '../services/alarm_service.dart';
import '../services/onboarding_service.dart';
import '../screens/settings/location_settings_screen.dart';
import '../screens/transit_data_screen.dart';
import 'destination_picker_sheet.dart';
import 'home_card.dart';

class TripSetupChecklist extends StatefulWidget {
  const TripSetupChecklist({super.key});

  @override
  State<TripSetupChecklist> createState() => _TripSetupChecklistState();
}

class _TripSetupChecklistState extends State<TripSetupChecklist> {
  bool _expanded = true;
  bool? _locationGranted;
  bool? _alarmTested;

  @override
  void initState() {
    super.initState();
    _refreshChecks();
  }

  Future<void> _refreshChecks() async {
    try {
      final permission = await Geolocator.checkPermission();
      final alarmTested = await OnboardingService().isAlarmTested();
      if (!mounted) {
        return;
      }
      setState(() {
        _locationGranted = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
        _alarmTested = alarmTested;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationGranted = false;
        _alarmTested = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        label: 'Location permission',
        complete: _locationGranted ?? false,
        onTap: () async {
          await Geolocator.requestPermission();
          await _refreshChecks();
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const LocationSettingsScreen(),
            ),
          );
        },
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
