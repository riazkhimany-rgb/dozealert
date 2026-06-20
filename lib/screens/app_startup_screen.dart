import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../providers/destination_history_provider.dart';
import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/trip_history_provider.dart';
import '../services/onboarding_service.dart';
import '../utils/app_branding.dart';
import '../widgets/branding_logo.dart';
import 'branded_splash_screen.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';

enum _StartupPhase {
  splash,
  loading,
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
      _phase = widget.skipBootstrap
          ? _StartupPhase.main
          : _StartupPhase.loading;
      FlutterNativeSplash.remove();
      if (!widget.skipBootstrap) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_bootstrap());
        });
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _startSplashTimer();
  }

  Future<void> _startSplashTimer() async {
    await Future<void>.delayed(AppBranding.splashDisplayDuration);
    if (!mounted) {
      return;
    }

    setState(() => _phase = _StartupPhase.loading);
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    final gtfsProvider = context.read<GtfsProvider>();
    final gtfsFeedProvider = context.read<GtfsFeedProvider>();
    final destinationHistoryProvider =
        context.read<DestinationHistoryProvider>();
    final tripHistoryProvider = context.read<TripHistoryProvider>();
    final onboardingService = context.read<OnboardingService>();

    await Future.wait([
      gtfsProvider.initialize(),
      gtfsFeedProvider.initialize(),
      destinationHistoryProvider.load(),
      tripHistoryProvider.load(),
    ]);

    if (!mounted) {
      return;
    }

    final onboardingComplete = await onboardingService.isComplete();
    if (!mounted) {
      return;
    }

    setState(() {
      _phase = onboardingComplete ? _StartupPhase.main : _StartupPhase.onboarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _StartupPhase.splash => const BrandedSplashScreen(),
      _StartupPhase.loading => const _BootstrapLoadingScreen(),
      _StartupPhase.onboarding => const OnboardingScreen(),
      _StartupPhase.main => const MainScreen(),
    };
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandingHero(
              logoHeight: 96,
              showDarkBadge: true,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading transit data…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
