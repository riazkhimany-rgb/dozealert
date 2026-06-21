import 'package:flutter/material.dart';

class MonitoringDistanceProgress extends StatelessWidget {
  const MonitoringDistanceProgress({
    super.key,
    required this.distanceKm,
    required this.progress,
    required this.accentColor,
    this.subtitle,
  });

  final double distanceKm;
  final double? progress;
  final Color accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = progress?.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          distanceKm.toStringAsFixed(1),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: accentColor,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'km remaining',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (fraction != null) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              color: accentColor,
            ),
          ),
        ],
      ],
    );
  }
}

class MonitoringStatusChip extends StatefulWidget {
  const MonitoringStatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;

  @override
  State<MonitoringStatusChip> createState() => _MonitoringStatusChipState();
}

class _MonitoringStatusChipState extends State<MonitoringStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MonitoringStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.color;
    final backgroundColor = widget.active
        ? colorScheme.surfaceContainerHighest
        : accent.withValues(alpha: 0.12);
    final borderColor = widget.active
        ? accent.withValues(alpha: 0.55)
        : accent.withValues(alpha: 0.35);

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.active) {
      return content;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glow = 0.18 + (_controller.value * 0.28);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: glow),
                blurRadius: 16 + (_controller.value * 10),
                spreadRadius: 1 + (_controller.value * 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: content,
    );
  }
}
