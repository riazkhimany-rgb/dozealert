import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../providers/destination_history_provider.dart';
import '../providers/monitoring_provider.dart';

class RecentDestinationsPickerSheet extends StatelessWidget {
  const RecentDestinationsPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final viewPadding = mediaQuery.viewPadding;
        final sheetHeight = (mediaQuery.size.height -
                viewPadding.top -
                viewPadding.bottom) *
            0.75;

        return Padding(
          padding: EdgeInsets.only(
            top: viewPadding.top,
            bottom: viewPadding.bottom + mediaQuery.viewInsets.bottom,
          ),
          child: SizedBox(
            height: sheetHeight,
            child: const RecentDestinationsPickerSheet(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recents = context.watch<DestinationHistoryProvider>().recents;
    final selected = context.select<MonitoringProvider, Destination?>(
      (provider) => provider.selectedDestination,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Recent destinations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            recents.isEmpty
                ? 'No recent destinations yet'
                : '${recents.length} recent destination${recents.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: recents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Destinations you pick will appear here for quick reuse.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: recents.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final destination = recents[index];
                    final isSelected =
                        selected != null && selected == destination;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.history,
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(destination.name),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () => unawaited(_select(context, destination)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static Future<void> _select(
    BuildContext context,
    Destination destination,
  ) async {
    await context.read<MonitoringProvider>().setDestination(destination);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${destination.name}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
