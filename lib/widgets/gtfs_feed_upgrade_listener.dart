import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';

class _UpgradeProgress {
  const _UpgradeProgress({
    required this.phase,
    required this.completed,
    required this.total,
  });

  final String phase;
  final int completed;
  final int total;
}

/// Runs GTFS cache upgrades after the app reaches Home — not on splash.
class GtfsFeedUpgradeListener extends StatefulWidget {
  const GtfsFeedUpgradeListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<GtfsFeedUpgradeListener> createState() =>
      _GtfsFeedUpgradeListenerState();
}

class _GtfsFeedUpgradeListenerState extends State<GtfsFeedUpgradeListener> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeUpgradeStaleFeeds());
    });
  }

  Future<void> _maybeUpgradeStaleFeeds() async {
    if (_started || !mounted) {
      return;
    }
    _started = true;

    final feedProvider = context.read<GtfsFeedProvider>();

    if (!feedProvider.isInitialized) {
      await feedProvider.initialize();
    }

    final staleFeeds = await feedProvider.listStaleFeeds();
    if (!mounted || staleFeeds.isEmpty) {
      return;
    }

    final names = staleFeeds.map((feed) => feed.agencyName).join(', ');
    final progress = ValueNotifier(
      _UpgradeProgress(
        phase: 'Preparing…',
        completed: 0,
        total: staleFeeds.length,
      ),
    );

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return ValueListenableBuilder<_UpgradeProgress>(
            valueListenable: progress,
            builder: (context, value, _) {
              return AlertDialog(
                title: const Text('Updating stop lists'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We improved how stations are grouped on your lines. '
                      'Refreshing $names — this usually takes a moment.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      value.phase,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: value.total == 0
                          ? null
                          : value.completed / value.total,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${value.completed} of ${value.total} done',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );

    final queuedDownloads = await feedProvider.upgradeStaleFeedsIfNeeded(
      onProgress: ({
        required String feedId,
        required String agencyName,
        required String progressPhase,
        required int completedFeeds,
        required int totalFeeds,
      }) {
        progress.value = _UpgradeProgress(
          phase: '$agencyName — $progressPhase',
          completed: completedFeeds,
          total: totalFeeds,
        );
      },
    );

    if (queuedDownloads.isNotEmpty) {
      feedProvider.queueBackgroundDownloads(queuedDownloads);
    }

    progress.dispose();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
