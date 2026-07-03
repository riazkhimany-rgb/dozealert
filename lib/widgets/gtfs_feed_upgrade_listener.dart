import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_feed_provider.dart';

class _UpgradeProgress {
  const _UpgradeProgress({
    required this.phase,
    required this.fraction,
  });

  final String phase;

  /// Overall completion across all feeds, 0..1.
  final double fraction;

  int get percent => (fraction.clamp(0.0, 1.0) * 100).round();
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

  // Progress state. The parse runs in an opaque isolate with no row-level
  // callbacks, so the real signal only advances once per feed. To avoid a bar
  // that looks frozen (especially with a single agency, where it would jump
  // 0 -> 100%), we ease a displayed fraction upward toward the current feed's
  // ceiling on a timer, and snap to the real value as each feed completes.
  ValueNotifier<_UpgradeProgress>? _progress;
  Timer? _creepTimer;
  int _totalFeeds = 1;
  double _displayed = 0;
  double _floor = 0;
  double _ceiling = 0;
  String _phase = 'Preparing…';

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
    _totalFeeds = staleFeeds.length;
    _displayed = 0;
    _floor = 0;
    // Start creeping toward the first feed's ceiling right away so the bar is
    // already moving before the first real progress callback arrives.
    _ceiling = _ceilingFor(0);
    _phase = 'Preparing…';
    _progress = ValueNotifier(
      _UpgradeProgress(phase: _phase, fraction: 0),
    );

    _creepTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      _tickCreep();
    });

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return ValueListenableBuilder<_UpgradeProgress>(
            valueListenable: _progress!,
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
                    LinearProgressIndicator(value: value.fraction),
                    const SizedBox(height: 4),
                    Text(
                      '${value.percent}%',
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
        _totalFeeds = totalFeeds == 0 ? 1 : totalFeeds;
        _phase = '$agencyName — $progressPhase';
        _floor = completedFeeds / _totalFeeds;
        _ceiling = _ceilingFor(completedFeeds);
        _publishProgress();
      },
    );

    if (queuedDownloads.isNotEmpty) {
      feedProvider.queueBackgroundDownloads(queuedDownloads);
    }

    // Settle the bar at 100% before dismissing so it never looks abandoned.
    _creepTimer?.cancel();
    _creepTimer = null;
    _displayed = 1.0;
    _phase = 'Done';
    _publishProgress();
    await Future<void>.delayed(const Duration(milliseconds: 250));

    _progress?.dispose();
    _progress = null;
    if (mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  /// Creep ceiling for the feed currently being processed. Stops just short of
  /// the next whole-feed boundary so the bar only completes a feed's share once
  /// that feed is genuinely done.
  double _ceilingFor(int completedFeeds) {
    final ceiling = (completedFeeds + 0.9) / _totalFeeds;
    return ceiling.clamp(0.0, 0.99);
  }

  void _tickCreep() {
    // Ease toward the ceiling; slows as it approaches so it stays believable.
    _displayed += (_ceiling - _displayed) * 0.08;
    _publishProgress();
  }

  void _publishProgress() {
    final notifier = _progress;
    if (notifier == null) {
      return;
    }
    // Keep it monotonic: never drop below the real completed floor, never
    // exceed the current creep ceiling (until the final settle to 1.0).
    if (_displayed < _floor) {
      _displayed = _floor;
    }
    if (_displayed > _ceiling && _displayed < 1.0) {
      _displayed = _ceiling;
    }
    notifier.value = _UpgradeProgress(phase: _phase, fraction: _displayed);
  }

  @override
  void dispose() {
    _creepTimer?.cancel();
    _creepTimer = null;
    _progress?.dispose();
    _progress = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
