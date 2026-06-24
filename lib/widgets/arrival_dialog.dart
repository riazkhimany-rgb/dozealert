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
    final destinationName = arrivalContext?.destinationName ?? 'Destination';
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
                  'Approaching destination',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppBranding.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  destinationName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppBranding.cyanAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppBranding.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppBranding.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  detailMessage ??
                      'Heads up! You are approaching your destination. '
                      'Voice alert and vibration will continue until you dismiss.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppBranding.white.withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 36),
                Semantics(
                  button: true,
                  label: 'Dismiss arrival alarm',
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.alarm_off_outlined),
                      label: const Text('Dismiss'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
