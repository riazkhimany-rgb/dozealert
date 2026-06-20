import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/alarm_service.dart';
import '../services/onboarding_service.dart';
import '../utils/app_branding.dart';
import '../widgets/alarm_test_page.dart';
import '../widgets/onboarding_permissions_page.dart';
import '../widgets/transit_preferences_section.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.popOnComplete = false,
  });

  /// When true, finishing or skipping returns to the previous screen instead
  /// of replacing the app root (used from the home first-time setup checklist).
  final bool popOnComplete;

  static const pageCount = 4;
  static const permissionsPageIndex = 1;
  static const alarmPageIndex = 3;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _pageIndex = 0;
  bool _permissionsReady = false;
  bool _alarmTestPlaying = false;
  bool _alarmTestCompleted = false;
  AlarmService? _alarmService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alarmService ??= context.read<AlarmService>();
  }

  @override
  void dispose() {
    if (_alarmTestPlaying) {
      unawaited(_alarmService?.stopAlarm());
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AlarmService>().stopAlarm();
    await _onboardingService.markComplete();
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

  Future<void> _playTestAlarm() async {
    await context.read<AlarmService>().playAlarm();
    if (!mounted) {
      return;
    }
    setState(() => _alarmTestPlaying = true);
  }

  Future<void> _stopTestAlarm() async {
    await context.read<AlarmService>().stopAlarm();
    await _onboardingService.markAlarmTested();
    if (!mounted) {
      return;
    }
    setState(() {
      _alarmTestPlaying = false;
      _alarmTestCompleted = true;
    });
  }

  Future<void> _onPrimaryAction() async {
    if (_pageIndex == OnboardingScreen.permissionsPageIndex &&
        !_permissionsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Grant the required permissions on this screen before continuing.',
          ),
        ),
      );
      return;
    }

    if (_pageIndex < OnboardingScreen.alarmPageIndex) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    if (_alarmTestPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop the test alarm before continuing.'),
        ),
      );
      return;
    }

    await _finish();
  }

  bool get _canPressPrimary {
    if (_pageIndex == OnboardingScreen.permissionsPageIndex) {
      return _permissionsReady;
    }
    if (_pageIndex == OnboardingScreen.alarmPageIndex) {
      return !_alarmTestPlaying;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.popOnComplete ? 'Setup guide' : 'Welcome'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(widget.popOnComplete ? 'Close' : 'Skip'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _pageIndex = index),
        children: [
          const _IntroPage(
            title: 'Wake up before your stop',
            body:
                'DozeAlert monitors your trip and sounds an alarm when '
                'you are approaching your destination.\n\n'
                'Set a wake radius (for example 1 km) so the alert '
                'fires with enough time to gather your things.',
            icon: Icons.notifications_active_outlined,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your transit agency',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional — helps pick stops and download the right '
                  'GTFS feed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: SingleChildScrollView(
                    child: TransitPreferencesSection(),
                  ),
                ),
              ],
            ),
          ),
          AlarmTestPage(
            alarmPlaying: _alarmTestPlaying,
            alarmTestCompleted: _alarmTestCompleted,
            onPlay: () => unawaited(_playTestAlarm()),
            onStop: () => unawaited(_stopTestAlarm()),
            completionMessage:
                'Volume saved. Tap Get started when you are ready.',
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
                    _pageIndex < OnboardingScreen.alarmPageIndex
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
                    'Complete the required permission steps above to continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (_pageIndex == OnboardingScreen.alarmPageIndex &&
                  _alarmTestPlaying)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Stop the test alarm when the volume feels right.',
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
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppBranding.splashLogoAsset,
            width: 96,
            height: 96,
          ),
          const SizedBox(height: 24),
          Icon(icon, size: 48, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
    );
  }
}
