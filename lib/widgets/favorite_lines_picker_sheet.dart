import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_transit_line.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/transit_provider.dart';
import '../utils/transit_line_switch.dart';

class FavoriteLinesPickerSheet extends StatelessWidget {
  const FavoriteLinesPickerSheet({super.key});

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
            child: const FavoriteLinesPickerSheet(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final favorites = context.watch<FavoriteTransitLineProvider>().favorites;
    final preferences = context.watch<TransitProvider>().preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Quick switch line',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            favorites.isEmpty
                ? 'Save lines on the Trips tab for quick switching.'
                : '${favorites.length} saved line${favorites.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: favorites.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No favorite lines yet. Add them from Settings → Transit '
                      'or the Trips tab.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final favorite = favorites[index];
                    final isSelected = favorite.matches(preferences);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.directions_transit_outlined,
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(favorite.label),
                      trailing: isSelected
                          ? Icon(Icons.check, color: colorScheme.primary)
                          : null,
                      onTap: () => unawaited(
                        TransitLineSwitch.applyAndPickStop(
                          context,
                          favorite,
                          popLinePickerFirst: true,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
