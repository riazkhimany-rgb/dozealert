import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_provider.dart';
import '../utils/trip_ux_copy.dart';
import 'destination_picker_sheet.dart';
import 'stop_picker_sheet.dart';
import 'transit_agency_line_picker_sheet.dart';

/// Combined route + stop picker — the primary entry point for trip setup.
class TripStopPickerSheet extends StatelessWidget {
  const TripStopPickerSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final gtfsProvider = context.read<GtfsProvider>();
    if (!gtfsProvider.canShowStopPicker()) {
      await DestinationPickerSheet.show(context);
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    final viewPadding = mediaQuery.viewPadding;
    final sheetHeight = (mediaQuery.size.height -
            viewPadding.top -
            viewPadding.bottom) *
        0.85;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: viewPadding.top,
            bottom: viewPadding.bottom + mediaQuery.viewInsets.bottom,
          ),
          child: SizedBox(
            height: sheetHeight,
            child: const TripStopPickerSheet(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedLine = context.watch<GtfsProvider>().selectedLineLabel;

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TripUxCopy.pickRoute,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedLine,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => TransitAgencyLinePickerSheet.show(context),
                child: Text(TripUxCopy.changeLine),
              ),
            ],
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
