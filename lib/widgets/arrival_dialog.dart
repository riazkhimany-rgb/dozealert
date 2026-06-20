import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/arrival_context.dart';
import '../providers/location_provider.dart';
import '../widgets/metric_row.dart';

class ArrivalDialog extends StatelessWidget {
  const ArrivalDialog({
    super.key,
    required this.onDismiss,
  });

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final arrivalContext = context.select<LocationProvider, ArrivalContext?>(
      (provider) => provider.arrivalContext,
    );
    final destinationName = arrivalContext?.destinationName ?? 'Destination';
    final usedTransitMode = arrivalContext?.usedTransitMode ?? false;
    final detailMessage = arrivalContext?.detailMessage;
    final distanceKm = arrivalContext?.distanceKm;
    final stopsRemaining = arrivalContext?.stopsRemaining;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Approaching destination alert',
                child: Icon(
                  Icons.place_rounded,
                  size: 88,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Approaching Destination',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                destinationName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              MetricRow(
                label: 'Wake mode',
                value: usedTransitMode ? 'Transit mode' : 'Distance',
              ),
              if (distanceKm != null) ...[
                const SizedBox(height: 8),
                MetricRow(
                  label: 'Distance',
                  value: '${distanceKm.toStringAsFixed(1)} km',
                ),
              ],
              if (usedTransitMode && stopsRemaining != null) ...[
                const SizedBox(height: 8),
                MetricRow(
                  label: 'Stops remaining',
                  value: stopsRemaining.toString(),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                detailMessage ??
                    'Heads up! You are approaching your destination. '
                    'Voice alert and vibration will continue until you dismiss.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              Semantics(
                button: true,
                label: 'Dismiss arrival alarm',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.alarm_off_outlined),
                    label: const Text('Dismiss'),
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
