import '../data/transit_catalog.dart';
import '../models/app_permission_snapshot.dart';
import '../models/transit_preferences.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import 'gtfs_readiness.dart';

enum TripReadinessIssue {
  destination,
  permissions,
  stopData,
}

class TripReadinessItem {
  const TripReadinessItem({
    required this.issue,
    required this.label,
    required this.complete,
    required this.actionLabel,
  });

  final TripReadinessIssue issue;
  final String label;
  final bool complete;
  final String actionLabel;
}

class TripReadinessSnapshot {
  const TripReadinessSnapshot({required this.items});

  final List<TripReadinessItem> items;

  bool get isReady => items.every((item) => item.complete);

  int get completeCount => items.where((item) => item.complete).length;
}

/// Checks whether the user can start a trip confidently.
abstract final class TripReadiness {
  static TripReadinessSnapshot evaluate({
    required bool transitModeEnabled,
    required bool hasDestination,
    required AppPermissionSnapshot? permissions,
    required TransitPreferences preferences,
    required GtfsProvider gtfsProvider,
    required GtfsFeedProvider feedProvider,
  }) {
    final items = <TripReadinessItem>[];

    items.add(
      TripReadinessItem(
        issue: TripReadinessIssue.destination,
        label: 'Destination chosen',
        complete: hasDestination,
        actionLabel: 'Set destination',
      ),
    );

    final permissionsReady = permissions?.allRequiredForMonitoring ?? false;
    items.add(
      TripReadinessItem(
        issue: TripReadinessIssue.permissions,
        label: 'Location and notification access',
        complete: permissionsReady,
        actionLabel: 'Fix permissions',
      ),
    );

    if (transitModeEnabled &&
        TransitCatalog.hasCatalogLines(preferences.transitSystem)) {
      final stopDataReady = GtfsReadiness.isSetupChecklistComplete(
        gtfsProvider,
        preferences,
        feedProvider,
      );
      items.add(
        TripReadinessItem(
          issue: TripReadinessIssue.stopData,
          label: '${preferences.transitSystem} stop list downloaded',
          complete: stopDataReady,
          actionLabel: 'Download stops',
        ),
      );
    }

    return TripReadinessSnapshot(items: items);
  }
}
