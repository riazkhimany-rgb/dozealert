import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_branding.dart';
import 'branding_logo.dart';

/// Identifiers for each Home screen guided-tour step.
enum HomeTourStepId {
  chooseAgency,
  setDestination,
  wakeSettings,
  startMonitoring,
}

/// Static copy for a single guided-tour step.
class HomeTourStepContent {
  const HomeTourStepContent({
    required this.id,
    required this.title,
    required this.body,
  });

  final HomeTourStepId id;
  final String title;
  final String body;
}

/// Branded tooltip card rendered by `showcaseview` for each tour step.
///
/// The card sizes itself and is positioned by the showcase engine, so it no
/// longer needs the fragile manual placement maths the old overlay relied on.
class HomeTourCard extends StatelessWidget {
  const HomeTourCard({
    super.key,
    required this.title,
    required this.body,
    required this.stepIndex,
    required this.stepCount,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final String title;
  final String body;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  bool get _isLast => stepIndex >= stepCount - 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(screenWidth - 40, 360).toDouble();

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cardWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppBranding.midnightBlue, Color(0xFF152536)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppBranding.cyanAccent.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppBranding.cyanAccent.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandingLogo(height: 26, showDarkBadge: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Step ${stepIndex + 1} of $stepCount',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppBranding.cyanAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 18),
                _ProgressDots(stepIndex: stepIndex, stepCount: stepCount),
                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.7),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Skip'),
                    ),
                    const Spacer(),
                    if (onBack != null)
                      TextButton(
                        onPressed: onBack,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 40),
                        ),
                        child: const Text('Back'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppBranding.cyanAccent,
                        foregroundColor: AppBranding.midnightBlue,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(
                        _isLast ? 'Done' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.stepIndex, required this.stepCount});

  final int stepIndex;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stepCount; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 5,
              margin: EdgeInsets.only(right: i == stepCount - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= stepIndex
                    ? AppBranding.cyanAccent
                    : Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}
