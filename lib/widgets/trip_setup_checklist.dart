import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/app_permission_snapshot.dart';
import '../models/gtfs_feed_info.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/transit_data_screen.dart';
import '../services/app_permissions_service.dart';
import '../widgets/onboarding_permissions_page.dart';
import 'home_card.dart';

class TripSetupChecklist extends StatefulWidget {
  const TripSetupChecklist({super.key});

  @override
  State<TripSetupChecklist> createState() => _TripSetupChecklistState();
}

class _TripSetupChecklistState extends State<TripSetupChecklist>
    with WidgetsBindingObserver {
  bool _expanded = false;
  AppPermissionSnapshot? _permissions;
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
      if (!mounted) {
        return;
      }
      setState(() {
        _permissions = snapshot;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _permissions = null;
      });
    }
  }

  Future<void> _openSetupGuide() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const OnboardingScreen(popOnComplete: true),
      ),
    );
    await _refreshChecks();
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
            ? 'Permissions (GPS, All the time location, Notifications, Battery)'
            : 'Permissions (GPS and location access)',
        complete: permissionsReady,
        onTap: _openPermissionsSetup,
      ),
    ];

    final completeCount = items.where((item) => item.complete).length;
    if (completeCount == items.length) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
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
                      title: 'First time setup ($completeCount/${items.length})',
                    ),
                  ),
                  Text(
                    _expanded ? 'Hide' : 'Show',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (_expanded) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => unawaited(_openSetupGuide()),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Open setup guide'),
                ),
              ),
              const SizedBox(height: 4),
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
        title: const Text('Permissions'),
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
