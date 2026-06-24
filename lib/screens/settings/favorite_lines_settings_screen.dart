import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/favorite_transit_line_provider.dart';
import '../../widgets/favorite_transit_lines_section.dart';

class FavoriteLinesSettingsScreen extends StatelessWidget {
  const FavoriteLinesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites =
        context.watch<FavoriteTransitLineProvider>().favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Lines'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          FavoriteTransitLinesSection(favorites: favorites),
        ],
      ),
    );
  }
}
