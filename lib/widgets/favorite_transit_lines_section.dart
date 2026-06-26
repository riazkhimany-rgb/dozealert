import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/favorite_transit_line.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../utils/transit_line_switch.dart';
import 'add_favorite_transit_line_sheet.dart';
import 'home_card.dart';

class FavoriteTransitLinesSection extends StatelessWidget {
  const FavoriteTransitLinesSection({
    super.key,
    required this.favorites,
    this.showHeaderAction = true,
  });

  final List<FavoriteTransitLine> favorites;
  final bool showHeaderAction;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: HomeCardHeader(
                  icon: Icons.swap_horiz,
                  title: 'Favorite Lines',
                  iconColor: Color(0xFF4CC9F0),
                ),
              ),
              if (showHeaderAction)
                TextButton.icon(
                  onPressed: () =>
                      unawaited(AddFavoriteTransitLineSheet.show(context)),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Quick-switch agency and line pairs from Home during transfers.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (favorites.isEmpty)
            Text(
              'No favorite lines saved yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...favorites.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_transit_outlined),
                title: Text(item.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      tooltip: 'Switch to this line',
                      onPressed: () => unawaited(_switchLine(context, item)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove favorite line',
                      onPressed: () async {
                        await context
                            .read<FavoriteTransitLineProvider>()
                            .remove(item);
                      },
                    ),
                  ],
                ),
                onTap: () => unawaited(_switchLine(context, item)),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _switchLine(
  BuildContext context,
  FavoriteTransitLine favorite,
) async {
  await TransitLineSwitch.applyAndPickStop(
    context,
    favorite,
    navigateHomeAfterStopSelection: true,
  );
}
