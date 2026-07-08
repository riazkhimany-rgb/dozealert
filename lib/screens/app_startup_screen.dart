import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../providers/destination_history_provider.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../providers/trip_history_provider.dart';
import '../services/onboarding_service.dart';
import '../services/transit_catalog_store.dart';
import '../utils/app_branding.dart';
import 'branded_splash_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

enum _StartupPhase {
  splash,
  bootstrapping,
  onboarding,
  main,
}

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({
    super.key,
    this.skipSplash = false,
    this.skipBootstrap = false,
  });

  final bool skipSplash;
  final bool skipBootstrap;

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  _StartupPhase _phase = _StartupPhase.splash;

  @override
  void initState() {
    super.initState();
    if (widget.skipSplash) {
      FlutterNativeSplash.remove();
      if (widget.skipBootstrap) {
        _phase = _StartupPhase.main;
        return;
      }
      _phase = _StartupPhase.bootstrapping;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_bootstrapAndTransition());
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    unawaited(_finishSplashAndBootstrap());
  }

  Future<void> _finishSplashAndBootstrap() async {
    if (widget.skipBootstrap) {
      await Future<void>.delayed(AppBranding.splashDisplayDuration);
      if (!mounted) {
        return;
      }
      setState(() => _phase = _StartupPhase.main);
      return;
    }

    final onboardingComplete = await Future.wait([
      Future<void>.delayed(AppBranding.splashDisplayDuration),
      _bootstrap(),
    ]).then((results) => results[1] as bool);

    if (!mounted) {
      return;
    }

    _setPhaseAfterBootstrap(onboardingComplete);
  }

  Future<void> _bootstrapAndTransition() async {
    final onboardingComplete = await _bootstrap();
    if (!mounted) {
      return;
    }
    _setPhaseAfterBootstrap(onboardingComplete);
  }

  Future<bool> _bootstrap() async {
    final catalogStore = context.read<TransitCatalogStore>();
    final gtfsProvider = context.read<GtfsProvider>();
    final gtfsFeedProvider = context.read<GtfsFeedProvider>();
    final destinationHistoryProvider =
        context.read<DestinationHistoryProvider>();
    final tripHistoryProvider = context.read<TripHistoryProvider>();
    final onboardingService = context.read<OnboardingService>();
    final transitProvider = context.read<TransitProvider>();

    // Feeds initialize from the bundled/cached catalog loaded in main(), so the
    // splash -> home transition never waits on the network.
    await gtfsFeedProvider.initialize();

    await Future.wait([
      gtfsProvider.initialize(),
      destinationHistoryProvider.load(),
      tripHistoryProvider.load(),
    ]);

    final transitSystem = transitProvider.preferences.transitSystem;
    final preloadFeed = feedForTransitSystemPreload(
      gtfsFeedProvider,
      transitSystem,
      const {},
    );
    if (preloadFeed != null) {
      gtfsFeedProvider.preloadFeedIfNeeded(
        preloadFeed,
        onComplete: () async {
          await gtfsProvider.refreshFromCache();
          await gtfsProvider.notifyDataUpdated();
        },
      );
    }

    // Refresh the agency list in the background; apply new feeds if the remote
    // catalog is newer. Off the critical path so it can't slow cold start.
    unawaited(
      catalogStore.refreshIfStale().then((updated) async {
        if (updated) {
          await gtfsFeedProvider.applyCatalogFeeds();
        }
      }),
    );

    return onboardingService.isComplete();
  }

  String? feedForTransitSystemPreload(
    GtfsFeedProvider feedProvider,
    String transitSystem,
    Set<String> alreadyQueued,
  ) {
    final feed = feedProvider.feedForTransitSystem(transitSystem);
    if (feed == null ||
        !feed.hasDirectDownload ||
        feed.isDownloaded ||
        alreadyQueued.contains(feed.feedId)) {
      return null;
    }
    return feed.feedId;
  }

  void _setPhaseAfterBootstrap(bool onboardingComplete) {
    setState(() {
      _phase = onboardingComplete ? _StartupPhase.main : _StartupPhase.onboarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _StartupPhase.splash => const BrandedSplashScreen(),
      _StartupPhase.bootstrapping => const _BootstrappingScreen(),
      _StartupPhase.onboarding => const OnboardingScreen(),
      _StartupPhase.main => const MainScreen(),
    };
  }
}

/// Plain navy screen while bootstrapping (tests / skipSplash only).
class _BootstrappingScreen extends StatelessWidget {
  const _BootstrappingScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppBranding.midnightBlue,
      child: Center(
        child: CircularProgressIndicator(color: AppBranding.cyanAccent),
      ),
    );
  }
}
