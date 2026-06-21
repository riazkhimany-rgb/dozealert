import 'package:flutter/material.dart';

import '../utils/app_branding.dart';

/// Subtle brand gradient behind scrollable content (dark theme especially).
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.light) {
      return child;
    }

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
      child: child,
    );
  }
}
