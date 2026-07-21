import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/gtfs_feed_provider.dart';
import '../../services/transit_catalog_store.dart';
import '../../widgets/settings_section_tile.dart';
import '../../utils/transit_user_copy.dart';
import 'favorite_lines_settings_screen.dart';
import '../transit_data_screen.dart';
import 'preferred_agencies_screen.dart';

class TransitSettingsScreen extends StatefulWidget {
  const TransitSettingsScreen({super.key});

  @override
  State<TransitSettingsScreen> createState() => _TransitSettingsScreenState();
}

class _TransitSettingsScreenState extends State<TransitSettingsScreen> {
  Future<void> _checkForCatalogUpdates() async {
    final catalogStore = context.read<TransitCatalogStore>();
    final feedProvider = context.read<GtfsFeedProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await catalogStore.forceRefresh();
    if (result.didUpdate) {
      await feedProvider.applyCatalogFeeds();
    }
    if (!mounted) {
      return;
    }

    switch (result.status) {
      case TransitCatalogRefreshStatus.updated:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Transit list updated (v${result.catalogVersion}). '
              'New agencies may now be available to download.',
            ),
          ),
        );
      case TransitCatalogRefreshStatus.upToDate:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Your transit list is already up to date '
              '(v${result.catalogVersion ?? catalogStore.catalogVersion}).',
            ),
          ),
        );
      case TransitCatalogRefreshStatus.incompatible:
        await _showUpdateAppDialog(result);
      case TransitCatalogRefreshStatus.failed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Could not reach the transit list. '
              'Check your connection and try again.',
            ),
          ),
        );
    }
  }

  Future<void> _showUpdateAppDialog(TransitCatalogRefreshResult result) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('App update needed'),
          content: Text(
            'A newer transit list (v${result.catalogVersion}) is available, '
            'but it needs DozeAlert ${result.minAppVersion} or later. '
            'Update the app from the Play Store to get the latest agencies.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogStore = context.watch<TransitCatalogStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: TransitUserCopy.transitAndLine),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              TransitUserCopy.settingsTransitAndLineIntro,
            ),
          ),
          const SizedBox(height: 8),
          SettingsNavTile(
            icon: Icons.apartment_outlined,
            title: TransitUserCopy.transitAndLine,
            subtitle: TransitUserCopy.settingsTransitAndLineSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PreferredAgenciesScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.star_outline,
            title: TransitUserCopy.favoriteLinesSectionTitle,
            subtitle: 'Saved transit lines for quick switching',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FavoriteLinesSettingsScreen(),
                ),
              );
            },
          ),
          SettingsNavTile(
            icon: Icons.cloud_download_outlined,
            title: 'Transit stops',
            subtitle: 'Download and update agency stop lists',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitDataScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Transit list'),
          SettingsNavTile(
            icon: Icons.sync,
            title: 'Check for updates',
            subtitle: catalogStore.isRefreshing
                ? 'Checking…'
                : 'Refresh the list of supported agencies (v${catalogStore.catalogVersion})',
            trailing: catalogStore.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: catalogStore.isRefreshing ? null : _checkForCatalogUpdates,
          ),
        ],
      ),
    );
  }
}
