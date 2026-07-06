import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wear_status_provider.dart';
import '../utils/trip_ux_copy.dart';

/// Green/red dot with watch reachability when the DozeAlert watch app is installed.
class WatchConnectionIndicator extends StatelessWidget {
  const WatchConnectionIndicator({
    super.key,
    required this.connected,
  });

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected
                ? const Color(0xFF34C759)
                : const Color(0xFFFF3B30),
          ),
        ),
        Text(
          connected
              ? TripUxCopy.watchConnected
              : TripUxCopy.watchNotConnected,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: connected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Shows [WatchConnectionIndicator] only after we confirm the DozeAlert watch
/// app is installed on a paired watch (Android only). Hidden when not installed.
class WatchConnectionIndicatorIfInstalled extends StatelessWidget {
  const WatchConnectionIndicatorIfInstalled({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final wearStatus = context.select<WearStatusProvider, ({bool checked, bool installed, bool connected})>(
      (provider) => (
        checked: provider.hasChecked,
        installed: provider.appInstalled,
        connected: provider.watchConnected,
      ),
    );

    if (!wearStatus.checked || !wearStatus.installed) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WatchConnectionIndicator(connected: wearStatus.connected),
        const SizedBox(height: 10),
      ],
    );
  }
}
