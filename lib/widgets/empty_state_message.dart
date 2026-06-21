import 'package:flutter/material.dart';

import 'branding_logo.dart';

class EmptyStateMessage extends StatelessWidget {
  const EmptyStateMessage({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showLogo = false,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLogo) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: BrandingLogo(height: 48),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
