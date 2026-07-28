import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../providers/wear_status_provider.dart';
import '../../widgets/branded_app_name.dart';
import '../../widgets/settings_section_tile.dart';

class WearSettingsScreen extends StatelessWidget {
  const WearSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final wearStatus = context.watch<WearStatusProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isAppleWatch = Platform.isIOS;
    final platformLabel = isAppleWatch ? 'Apple Watch' : 'Wear OS';

    final connectionSubtitle = !wearStatus.hasChecked
        ? 'Checking watch connection…'
        : !wearStatus.appInstalled
            ? isAppleWatch
                ? 'Watch app not detected on a paired Apple Watch'
                : 'Wear app not detected on a paired watch'
            : wearStatus.watchConnected
                ? 'DozeAlert watch app connected'
                : 'Watch app installed — watch not reachable right now';

    final openWatchSubtitle = isAppleWatch
        ? 'When on, starting a trip on the phone also opens DozeAlert on '
            'your Apple Watch. Turn off to keep the watch face visible and '
            'rely on the complication for status.'
        : 'When on, starting a trip on the phone also opens DozeAlert on '
            'your watch. Turn off to keep the watch face visible and rely on '
            'the complication or the DozeAlert trip tile for status.';

    return Scaffold(
      appBar: AppBar(
        title: Text(platformLabel),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const SettingsSectionHeader(title: 'Companion'),
          ListTile(
            leading: Icon(Icons.watch_outlined, color: colorScheme.primary),
            title: const Text('Watch connection'),
            subtitle: BrandedMentionText(
              connectionSubtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          SwitchListTile(
            secondary: Icon(Icons.open_in_new, color: colorScheme.primary),
            title: const Text('Open watch app when trip starts'),
            subtitle: BrandedMentionText(
              openWatchSubtitle,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: settings.openWatchAppWhenTripStarts,
            onChanged: (value) {
              unawaited(settings.setOpenWatchAppWhenTripStarts(value));
            },
          ),
        ],
      ),
    );
  }
}
