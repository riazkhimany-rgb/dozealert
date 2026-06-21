import 'package:flutter/material.dart';

import '../utils/app_branding.dart';
import 'branding_logo.dart';

class BrandedAppBarTitle extends StatelessWidget {
  const BrandedAppBarTitle({super.key});

  static const _logoHeight = 26.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandingLogo(height: _logoHeight, showDarkBadge: true),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(
                text: 'Doze',
                style: TextStyle(color: onSurface),
              ),
              TextSpan(
                text: 'Alert',
                style: TextStyle(color: AppBranding.cyanAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
