import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/app_tour_service.dart';
import '../services/onboarding_service.dart';
import '../utils/transit_user_copy.dart';
import '../utils/trip_ux_copy.dart';
import '../widgets/branded_app_name.dart';
import '../widgets/branding_logo.dart';
import '../widgets/onboarding_permissions_page.dart';
import '../widgets/transit_agency_choice_page.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.popOnComplete = false,
  });

  /// When true, finishing or skipping returns to the previous screen instead
  /// of replacing the app root (used from the home first-time setup checklist).
  final bool popOnComplete;

  static const pageCount = 3;
  static const introPageIndex = 0;
  static const agencyPageIndex = 1;
  static const permissionsPageIndex = 2;
  static const lastPageIndex = pageCount - 1;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<OnboardingPermissionsPageState> _permissionsPageKey =
      GlobalKey<OnboardingPermissionsPageState>();
  final OnboardingService _onboardingService = OnboardingService();
  int _pageIndex = 0;
  final Set<String> _selectedAgencies = {};
  String? _primaryAgency;
  bool _permissionsReady = false;
  bool _permissionsSetupStarted = false;
  bool _permissionsFlowRunning = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAgency(String agency) {
    setState(() {
      if (_selectedAgencies.contains(agency)) {
        _selectedAgencies.remove(agency);
        if (_primaryAgency == agency) {
          _primaryAgency =
              _selectedAgencies.isEmpty ? null : _selectedAgencies.first;
        }
      } else {
        _selectedAgencies.add(agency);
        _primaryAgency ??= agency;
      }
    });
  }

  void _setPrimaryAgency(String agency) {
    if (!_selectedAgencies.contains(agency)) {
      return;
    }
    setState(() => _primaryAgency = agency);
  }

  Future<void> _finish() async {
    if (_selectedAgencies.isNotEmpty && _primaryAgency != null) {
      await TransitAgencyChoicePage.applySelections(
        context,
        primaryAgency: _primaryAgency!,
        selectedAgencies: _selectedAgencies,
      );
    }
    await _onboardingService.markComplete();
    if (!mounted) {
      return;
    }
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
      Navigator.of(context).pop();
      return;
    }

    final skip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Leave setup?'),
          content: const Text(
            'DozeAlert needs permissions before it can watch your trip '
            'while you sleep.\n\n'
            'You can finish setup from Settings → Permissions anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep going'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Leave for now'),
            ),
          ],
        );
      },
    );

    if (skip == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _onPrimaryAction() async {
    if (_pageIndex == OnboardingScreen.agencyPageIndex &&
        _selectedAgencies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(TransitUserCopy.selectTransitToContinue),
        ),
      );
      return;
    }

    if (_pageIndex == OnboardingScreen.agencyPageIndex &&
        _primaryAgency != null) {
      await TransitAgencyChoicePage.applySelections(
        context,
        primaryAgency: _primaryAgency!,
        selectedAgencies: _selectedAgencies,
      );
      if (!mounted) {
        return;
      }
    }

    if (_pageIndex == OnboardingScreen.permissionsPageIndex) {
      if (_permissionsReady) {
        await _finish();
        return;
      }
      await _permissionsPageKey.currentState?.handleBottomPrimaryAction();
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
    if (_pageIndex == OnboardingScreen.agencyPageIndex) {
      return _selectedAgencies.isNotEmpty && _primaryAgency != null;
    }
    if (_pageIndex == OnboardingScreen.permissionsPageIndex) {
      return !_permissionsFlowRunning;
    }
    return true;
  }

  String get _primaryButtonLabel {
    if (_pageIndex == OnboardingScreen.permissionsPageIndex) {
      if (_permissionsReady) {
        return 'Get started';
      }
      if (_permissionsSetupStarted) {
        return TripUxCopy.resumePermissionSetup;
      }
      return TripUxCopy.enableAndContinue;
    }
    if (_pageIndex < OnboardingScreen.lastPageIndex) {
      return 'Continue';
    }
    return 'Get started';
  }

  String? get _primaryButtonHint {
    if (_pageIndex == OnboardingScreen.permissionsPageIndex &&
        _permissionsFlowRunning) {
      return 'Follow the Android prompts…';
    }
    if (_pageIndex == OnboardingScreen.permissionsPageIndex &&
        _permissionsSetupStarted &&
        !_permissionsReady &&
        !_permissionsFlowRunning) {
      return 'Finish the remaining steps above, or tap Resume setup.';
    }
    if (_pageIndex == OnboardingScreen.agencyPageIndex &&
        _selectedAgencies.isEmpty) {
      return TransitUserCopy.selectTransitAbove;
    }
    return null;
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
          if (widget.popOnComplete)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            )
          else
            TextButton(
              onPressed: _confirmSkipSetup,
              child: const Text('Leave for now'),
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: _pagePhysics,
        onPageChanged: (index) => setState(() => _pageIndex = index),
        children: [
          const _IntroPage(
            title: TripUxCopy.onboardingIntroTitle,
            body: TripUxCopy.onboardingIntroBody,
            useBrandMentions: true,
          ),
          TransitAgencyChoicePage(
            selectedAgencies: _selectedAgencies,
            primaryAgency: _primaryAgency,
            onAgencyToggled: _toggleAgency,
            onPrimaryChanged: _setPrimaryAgency,
          ),
          OnboardingPermissionsPage(
            key: _permissionsPageKey,
            onStatusChanged: (snapshot) {
              if (!mounted) {
                return;
              }
              setState(() {
                _permissionsReady = snapshot.allRequiredForMonitoring(
                  requireActivityRecognition: context
                      .read<SettingsProvider>()
                      .activityRecognitionEnabled,
                );
              });
            },
            onUiStateChanged: (state) {
              if (!mounted) {
                return;
              }
              setState(() {
                _permissionsSetupStarted = state.setupStarted;
                _permissionsFlowRunning = state.autoFlowRunning;
                _permissionsReady = state.permissionsReady;
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
                  onPressed:
                      _canPressPrimary ? () => unawaited(_onPrimaryAction()) : null,
                  child: _permissionsFlowRunning
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_primaryButtonLabel),
                          ],
                        )
                      : Text(_primaryButtonLabel),
                ),
              ),
              if (_primaryButtonHint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _primaryButtonHint!,
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
