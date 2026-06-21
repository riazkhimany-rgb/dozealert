import 'package:flutter/material.dart';

import '../models/transit_stop.dart';

enum _RouteDotKind { current, upcoming, destination, ellipsis }

class _RouteDot {
  const _RouteDot({
    this.stop,
    required this.kind,
  });

  final TransitStop? stop;
  final _RouteDotKind kind;
}

/// Horizontal stop-by-stop progress for transit mode on the home screen.
class TransitRouteProgressLine extends StatelessWidget {
  const TransitRouteProgressLine({
    super.key,
    required this.isActive,
    required this.stops,
    required this.stopsRemaining,
    this.lineLabel,
    this.inactiveMessage =
        'Start monitoring on your line to see stop-by-stop progress.',
  });

  final bool isActive;
  final List<TransitStop> stops;
  final int stopsRemaining;
  final String? lineLabel;
  final String inactiveMessage;

  static const _maxDots = 13;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isActive || stops.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lineLabel != null) ...[
            Text(
              lineLabel!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            inactiveMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    final dots = _condenseStops(stops);
    final currentName = stops.first.stopName;
    final destinationName = stops.last.stopName;
    final stopsLabel = stopsRemaining == 0
        ? 'At destination stop'
        : stopsRemaining == 1
            ? '1 stop to go'
            : '$stopsRemaining stops to go';

    return Semantics(
      label:
          'Transit progress on $lineLabel. Currently at $currentName. '
          '$stopsLabel before $destinationName.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lineLabel != null) ...[
            Text(
              lineLabel!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  _shortStopName(currentName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  stopsLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _shortStopName(destinationName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 28,
            child: CustomPaint(
              painter: _TransitRouteProgressPainter(
                dotCount: dots.length,
                colorScheme: colorScheme,
                kinds: dots.map((dot) => dot.kind).toList(growable: false),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < dots.length; i++)
                    Expanded(
                      child: Center(
                        child: _RouteDotIcon(
                          kind: dots[i].kind,
                          colorScheme: colorScheme,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<_RouteDot> _condenseStops(List<TransitStop> stops) {
    if (stops.length <= _maxDots) {
      return [
        for (var i = 0; i < stops.length; i++)
          _RouteDot(
            stop: stops[i],
            kind: i == 0
                ? _RouteDotKind.current
                : i == stops.length - 1
                    ? _RouteDotKind.destination
                    : _RouteDotKind.upcoming,
          ),
      ];
    }

    final condensed = <_RouteDot>[
      _RouteDot(stop: stops.first, kind: _RouteDotKind.current),
    ];

    final middleSlots = _maxDots - 3;
    final middleStops = stops.sublist(1, stops.length - 1);
    if (middleStops.length <= middleSlots) {
      condensed.addAll(
        middleStops.map((stop) => _RouteDot(stop: stop, kind: _RouteDotKind.upcoming)),
      );
    } else {
      condensed.add(const _RouteDot(kind: _RouteDotKind.ellipsis));
      final step = middleStops.length / (middleSlots - 1);
      for (var i = 0; i < middleSlots - 1; i++) {
        final index = (step * i).round().clamp(0, middleStops.length - 1);
        condensed.add(
          _RouteDot(stop: middleStops[index], kind: _RouteDotKind.upcoming),
        );
      }
    }

    condensed.add(
      _RouteDot(stop: stops.last, kind: _RouteDotKind.destination),
    );
    return condensed;
  }

  static String _shortStopName(String name) {
    return name.replaceAll(RegExp(r'\s+GO$'), '').trim();
  }
}

class _RouteDotIcon extends StatelessWidget {
  const _RouteDotIcon({
    required this.kind,
    required this.colorScheme,
  });

  final _RouteDotKind kind;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _RouteDotKind.current:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.onPrimary, width: 2),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.45),
                blurRadius: 6,
              ),
            ],
          ),
        );
      case _RouteDotKind.destination:
        return Icon(
          Icons.flag_rounded,
          size: 18,
          color: colorScheme.secondary,
        );
      case _RouteDotKind.ellipsis:
        return Text(
          '…',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        );
      case _RouteDotKind.upcoming:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
        );
    }
  }
}

class _TransitRouteProgressPainter extends CustomPainter {
  _TransitRouteProgressPainter({
    required this.dotCount,
    required this.colorScheme,
    required this.kinds,
  });

  final int dotCount;
  final ColorScheme colorScheme;
  final List<_RouteDotKind> kinds;

  @override
  void paint(Canvas canvas, Size size) {
    if (dotCount < 2) {
      return;
    }

    final y = size.height / 2;
    final segmentWidth = size.width / dotCount;
    final startX = segmentWidth / 2;
    final endX = size.width - segmentWidth / 2;

    final basePaint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), basePaint);

    final progressPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    var progressEnd = startX;
    for (var i = 1; i < dotCount; i++) {
      if (kinds[i] == _RouteDotKind.ellipsis) {
        break;
      }
      progressEnd = startX + segmentWidth * i;
    }
    if (progressEnd > startX) {
      canvas.drawLine(Offset(startX, y), Offset(progressEnd, y), progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TransitRouteProgressPainter oldDelegate) {
    return oldDelegate.dotCount != dotCount ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.kinds != kinds;
  }
}
