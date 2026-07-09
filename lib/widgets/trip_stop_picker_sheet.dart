import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transit_line_option.dart';
import '../providers/gtfs_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transit_provider.dart';
import '../screens/map_picker_screen.dart';
import '../utils/trip_ux_copy.dart';
import 'destination_picker_sheet.dart';
import 'stop_picker_sheet.dart';
import 'transit_agency_line_picker_sheet.dart';

/// Combined route + stop picker — the primary entry point for trip setup.
class TripStopPickerSheet extends StatelessWidget {
  const TripStopPickerSheet({super.key});

  static Future<void> show(BuildContext context) async {
    if (!context.read<SettingsProvider>().transitModeEnabled) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const MapPickerScreen(),
        ),
      );
      return;
    }

    final gtfsProvider = context.read<GtfsProvider>();
    await gtfsProvider.ensureSelectedFeedLoaded();
    if (!gtfsProvider.canShowStopPicker()) {
      await DestinationPickerSheet.show(context);
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SizedBox(
          height: maxHeight,
          child: const TripStopPickerSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preferences = context.watch<TransitProvider>().preferences;
    final gtfsProvider = context.watch<GtfsProvider>();
    final agency = preferences.transitSystem;
    final lineOptions = gtfsProvider.availableLineOptionsForSelectedAgency();
    final selectedOption = gtfsProvider.lineOptionForPreference(
          preferences.defaultLine,
          lineOptions,
        ) ??
        TransitLineOption(
          lineName: preferences.defaultLine,
          displayLabel: gtfsProvider.displayLabelForSelectedLine(),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            TripUxCopy.pickYourStop,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    agency,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedOption.shortDashLongLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => TransitAgencyLinePickerSheet.show(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(TripUxCopy.changeLine),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      alignment: Alignment.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        const Expanded(
          child: StopPickerSheet(compactHeader: true),
        ),
      ],
    );
  }
}
