import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_transit_line.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/transit_provider.dart';
import '../utils/transit_line_switch.dart';

/// Quick-switch chips for user-saved agency + line favorites.
class FavoriteTransitLineChips extends StatelessWidget {
  const FavoriteTransitLineChips({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteTransitLineProvider>().favorites;
    final preferences = context.watch<TransitProvider>().preferences;

    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick switch line',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final favorite in favorites)
              FilterChip(
                label: Text(favorite.label),
                selected: favorite.matches(preferences),
                onSelected: (selected) {
                  if (selected) {
                    unawaited(_switchTo(context, favorite));
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _switchTo(
    BuildContext context,
    FavoriteTransitLine favorite,
  ) async {
    final result = await TransitLineSwitch.apply(context, favorite);
    if (context.mounted) {
      TransitLineSwitch.showResultSnackBar(context, result, favorite);
    }
  }
}
