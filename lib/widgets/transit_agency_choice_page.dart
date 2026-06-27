import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/favorite_transit_line.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../utils/transit_user_copy.dart';

/// First-run agency picker — supports one or many agencies.
class TransitAgencyChoicePage extends StatelessWidget {
  const TransitAgencyChoicePage({
    super.key,
    required this.selectedAgencies,
    required this.primaryAgency,
    required this.onAgencyToggled,
    required this.onPrimaryChanged,
  });

  final Set<String> selectedAgencies;
  final String? primaryAgency;
  final ValueChanged<String> onAgencyToggled;
  final ValueChanged<String> onPrimaryChanged;

  static const country = 'Canada';
  static const region = 'Ontario';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final agencies = TransitCatalog.agenciesForRegion(country, region);
    final showPrimaryPicker = selectedAgencies.length > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.directions_transit,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Which transit do you ride?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select all that apply — for example if one trip uses both '
                  'TTC and GO Transit. We download stop lists in the '
                  'background for each one you pick.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ...agencies.map(
                  (agency) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AgencyTile(
                      agencyName: agency,
                      selected: selectedAgencies.contains(agency),
                      isPrimary: primaryAgency == agency,
                      showPrimaryBadge: showPrimaryPicker,
                      onTap: () => onAgencyToggled(agency),
                    ),
                  ),
                ),
                if (showPrimaryPicker) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Default on Home',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TransitUserCopy.defaultOnHomeHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...selectedAgencies.map(
                    (agency) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _PrimaryAgencyTile(
                        agencyName: agency,
                        selected: primaryAgency == agency,
                        onTap: () => onPrimaryChanged(agency),
                      ),
                    ),
                  ),
                ],
                if (selectedAgencies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    selectedAgencies.length == 1
                        ? TransitUserCopy.downloadStopListFor(
                            selectedAgencies.first,
                          )
                        : 'Downloading stops for ${selectedAgencies.length} agencies…',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Saves the primary agency, preloads stop lists, and seeds favorite lines.
  static Future<void> applySelections(
    BuildContext context, {
    required String primaryAgency,
    required Set<String> selectedAgencies,
  }) async {
    if (selectedAgencies.isEmpty) {
      return;
    }

    final transitProvider = context.read<TransitProvider>();
    final gtfsFeedProvider = context.read<GtfsFeedProvider>();
    final gtfsProvider = context.read<GtfsProvider>();
    final favoriteLines = context.read<FavoriteTransitLineProvider>();

    await transitProvider.applyTransitSelection(
      country: country,
      region: region,
      transitSystem: primaryAgency,
      defaultLine: TransitCatalog.defaultLineForSystem(primaryAgency),
    );
    await transitProvider.savePreferences();

    for (final agency in selectedAgencies) {
      gtfsFeedProvider.preloadForTransitSystemIfNeeded(
        agency,
        onComplete: gtfsProvider.notifyDataUpdated,
      );

      await favoriteLines.add(
        FavoriteTransitLine(
          country: country,
          region: region,
          transitSystem: agency,
          lineName: TransitCatalog.defaultLineForSystem(agency),
        ),
      );
    }
  }
}

class _AgencyTile extends StatelessWidget {
  const _AgencyTile({
    required this.agencyName,
    required this.selected,
    required this.isPrimary,
    required this.showPrimaryBadge,
    required this.onTap,
  });

  final String agencyName;
  final bool selected;
  final bool isPrimary;
  final bool showPrimaryBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  agencyName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showPrimaryBadge && isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Default',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryAgencyTile extends StatelessWidget {
  const _PrimaryAgencyTile({
    required this.agencyName,
    required this.selected,
    required this.onTap,
  });

  final String agencyName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colorScheme.primary : colorScheme.outline,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  agencyName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
