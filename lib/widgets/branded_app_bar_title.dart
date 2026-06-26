import 'package:flutter/material.dart';

import 'branded_app_name.dart';
import 'branding_logo.dart';
class BrandedAppBarTitle extends StatelessWidget {
  const BrandedAppBarTitle({super.key});

  static const _logoHeight = 26.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandingLogo(height: _logoHeight, showDarkBadge: true),
        const SizedBox(width: 10),
        BrandedAppName(
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          dozeColor: theme.colorScheme.onSurface,
        ),
      ],
    );
  }
}
