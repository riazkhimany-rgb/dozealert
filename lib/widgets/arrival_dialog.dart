import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/arrival_context.dart';
import '../providers/location_provider.dart';
import '../utils/app_branding.dart';
import '../widgets/branding_logo.dart';

class ArrivalDialog extends StatelessWidget {
  const ArrivalDialog({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final arrivalContext = context.select<LocationProvider, ArrivalContext?>(
      (provider) => provider.arrivalContext,
    );
    final headline = arrivalContext?.headline ?? 'Destination';
    final statusLine = arrivalContext?.wearSubline;
    final currentStopName =
        arrivalContext?.currentStopName ?? arrivalContext?.destinationName;
    final showCurrentStop = currentStopName != null &&
        currentStopName.toLowerCase() != headline.toLowerCase();
    final secondaryLine = arrivalContext?.secondaryLine;
    final detailMessage = arrivalContext?.detailMessage;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppBranding.midnightBlue,
            Color(0xFF152536),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppBranding.cyanAccent.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const BrandingLogo(height: 96, showDarkBadge: false),
                ),
                const SizedBox(height: 28),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppBranding.white,
                  ),
                ),
                if (statusLine != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    statusLine,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppBranding.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                if (showCurrentStop) ...[
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppBranding.white.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                      children: [
                        const TextSpan(text: 'You are at '),
                        TextSpan(
                          text: currentStopName!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppBranding.cyanAccent,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (secondaryLine != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    secondaryLine,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppBranding.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                Semantics(
                  button: true,
                  label: 'Dismiss arrival alarm',
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.alarm_off_rounded, size: 24),
                      label: const Text('Dismiss'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppBranding.cyanAccent,
                        foregroundColor: AppBranding.midnightBlue,
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 6,
                        shadowColor:
                            AppBranding.cyanAccent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                if (detailMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    detailMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppBranding.white.withValues(alpha: 0.72),
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
