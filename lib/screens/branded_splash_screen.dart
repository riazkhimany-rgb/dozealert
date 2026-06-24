import 'package:flutter/material.dart';

import '../utils/app_branding.dart';
import '../widgets/branding_logo.dart';

/// Static in-app splash shown briefly after the native splash is removed.
class BrandedSplashScreen extends StatelessWidget {
  const BrandedSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppBranding.midnightBlue,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: BrandingHero(
              logoHeight: 140,
              showDarkBadge: false,
              onDarkBackground: true,
            ),
          ),
        ),
      ),
    );
  }
}
