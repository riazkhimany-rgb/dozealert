import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/gtfs_feed_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/transit_provider.dart';
import '../services/app_tour_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/branded_app_name.dart';
import '../widgets/branding_logo.dart';
import '../widgets/onboarding_permissions_page.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.popOnComplete = false,
  });

  /// When true, finishing or skipping returns to the previous screen instead
  /// of replacing the app root (used from the home first-time setup checklist).
  final bool popOnComplete;

  static const pageCount = 2;
  static const permissionsPageIndex = 1;
  static const lastPageIndex = pageCount - 1;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _pageIndex = 0;
  bool _permissionsReady = false;
  bool _onboardingSetupStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startOnboardingSetup());
    });
  }

  Future<void> _startOnboardingSetup() async {
    if (_onboardingSetupStarted || !mounted) {
      return;
    }
    _onboardingSetupStarted = true;

    final transitProvider = context.read<TransitProvider>();
    final gtfsFeedProvider = context.read<GtfsFeedProvider>();
    final gtfsProvider = context.read<GtfsProvider>();

    await transitProvider.applyGoTransitDefaultsIfUnset();
    if (!mounted) {
      return;
    }

    gtfsFeedProvider.preloadGoTransitIfNeeded(
      onComplete: gtfsProvider.notifyDataUpdated,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await _startOnboardingSetup();
    await _onboardingService.markComplete();
    await context.read<AppTourService>().markHomeTourPending();
    if (!mounted) {
      return;
    }
    if (widget.popOnComplete) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainScreen()),
    );
  }

  Future<void> _confirmSkipSetup() async {
    if (widget.popOnComplete) {
      await _finish();
      return;
    }

    final skip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Skip setup?'),
          content: const Text(
            'You can use DozeAlert later, but trip monitoring needs location, '
            'notification, and battery permissions first.\n\n'
            'You can finish setup anytime from Home → First time setup or '
            'Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep setup'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Skip for now'),
            ),
          ],
        );
      },
    );

    if (skip == true && mounted) {
      await _finish();
    }
  }

  Future<void> _onPrimaryAction() async {
    if (_pageIndex == OnboardingScreen.permissionsPageIndex &&
        !_permissionsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete permission setup on this screen before continuing.',
          ),
        ),
      );
      return;
    }

    if (_pageIndex < OnboardingScreen.lastPageIndex) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    await _finish();
  }

  bool get _canPressPrimary {
    if (_pageIndex == OnboardingScreen.permissionsPageIndex) {
      return _permissionsReady;
    }
    return true;
  }

  ScrollPhysics get _pagePhysics {
    if (_pageIndex == OnboardingScreen.permissionsPageIndex &&
        !_permissionsReady) {
      return const NeverScrollableScrollPhysics();
    }
    return const PageScrollPhysics();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.popOnComplete ? 'Setup guide' : 'Welcome'),
        actions: [
          TextButton(
            onPressed: _confirmSkipSetup,
            child: Text(widget.popOnComplete ? 'Close' : 'Skip setup'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: _pagePhysics,
        onPageChanged: (index) => setState(() => _pageIndex = index),
        children: [
          const _IntroPage(
            title: 'Wake up before your stop',
            body:
                'DozeAlert monitors your trip and sounds an alarm when '
                'you are approaching your destination.\n\n'
                'Transit Mode is on by default — wake by stops remaining '
                'on your line. Turn it off on Home to use a distance '
                'wake radius instead (for example 1 km).\n\n'
                'Transit stop data downloads in the background while '
                'you finish setup.\n\n'
                'On Home, a guided tour will walk you through each step '
                'one at a time.',
            useBrandMentions: true,
          ),
          OnboardingPermissionsPage(
            onStatusChanged: (snapshot) {
              if (!mounted) {
                return;
              }
              setState(() {
                _permissionsReady = snapshot.allRequiredForMonitoring;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (var i = 0; i < OnboardingScreen.pageCount; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: i == OnboardingScreen.pageCount - 1 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: i <= _pageIndex
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canPressPrimary ? _onPrimaryAction : null,
                  child: Text(
                    _pageIndex < OnboardingScreen.lastPageIndex
                        ? 'Continue'
                        : 'Get started',
                  ),
                ),
              ),
              if (_pageIndex == OnboardingScreen.permissionsPageIndex &&
                  !_permissionsReady)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tap Start permission setup, then return here when done.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.title,
    required this.body,
    this.useBrandMentions = false,
  });

  final String title;
  final String body;
  final bool useBrandMentions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandingLogo(height: 120),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (useBrandMentions)
                  BrandedMentionText(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    dozeColor: colorScheme.onSurfaceVariant,
                  )
                else
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
