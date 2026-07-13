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
  /// of replacing the app root (used when reopening setup from Settings).
  final bool popOnComplete;

  static const pageCount = 4;
  static const introPageIndex = 0;
  static const modePageIndex = 1;
  static const agencyPageIndex = 2;
  static const permissionsPageIndex = 3;
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
  bool? _wantsTransitMode;
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
      final messenger = ScaffoldMessenger.of(context);
      await _onboardingService.markComplete();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text(TripUxCopy.onboardingSkipSnackBar)),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _goToPage(int index) async {
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onPrimaryAction() async {
    if (_pageIndex == OnboardingScreen.modePageIndex) {
      if (_wantsTransitMode == null) {
        return;
      }
      await context.read<SettingsProvider>().setTransitModeEnabled(
            _wantsTransitMode!,
          );
      if (!mounted) {
        return;
      }
      if (_wantsTransitMode!) {
        await _goToPage(OnboardingScreen.agencyPageIndex);
      } else {
        await _goToPage(OnboardingScreen.permissionsPageIndex);
      }
      return;
    }

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
      await _goToPage(_pageIndex + 1);
      return;
    }

    await _finish();
  }

  bool get _canPressPrimary {
    if (_pageIndex == OnboardingScreen.modePageIndex) {
      return _wantsTransitMode != null;
    }
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
    if (_pageIndex == OnboardingScreen.modePageIndex &&
        _wantsTransitMode == null) {
      return 'Choose transit or map-based travel above.';
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

  void _onPageChanged(int index) {
    if (_wantsTransitMode == false &&
        index == OnboardingScreen.agencyPageIndex) {
      final target = _pageIndex < index
          ? OnboardingScreen.permissionsPageIndex
          : OnboardingScreen.modePageIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _pageController.jumpToPage(target);
        setState(() => _pageIndex = target);
      });
      return;
    }
    setState(() => _pageIndex = index);
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
        onPageChanged: _onPageChanged,
        children: [
          const _IntroPage(
            title: TripUxCopy.onboardingIntroTitle,
            body: TripUxCopy.onboardingIntroBody,
            useBrandMentions: true,
          ),
          _ModeChoicePage(
            wantsTransitMode: _wantsTransitMode,
            onChanged: (value) => setState(() => _wantsTransitMode = value),
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

class _ModeChoicePage extends StatelessWidget {
  const _ModeChoicePage({
    required this.wantsTransitMode,
    required this.onChanged,
  });

  final bool? wantsTransitMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          TripUxCopy.onboardingModeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          TripUxCopy.onboardingModeBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _ModeOptionCard(
          icon: Icons.directions_transit_outlined,
          title: TripUxCopy.onboardingModeTransitTitle,
          subtitle: TripUxCopy.onboardingModeTransitSubtitle,
          selected: wantsTransitMode == true,
          onTap: () => onChanged(true),
        ),
        const SizedBox(height: 12),
        _ModeOptionCard(
          icon: Icons.map_outlined,
          title: TripUxCopy.onboardingModeDistanceTitle,
          subtitle: TripUxCopy.onboardingModeDistanceSubtitle,
          selected: wantsTransitMode == false,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.55)
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
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
