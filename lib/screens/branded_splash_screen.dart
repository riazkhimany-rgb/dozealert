import 'package:flutter/material.dart';

import '../utils/app_branding.dart';

class BrandedSplashScreen extends StatelessWidget {
  const BrandedSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return ColoredBox(
      color: AppBranding.midnightBlue,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: size.height * 0.04,
            ),
            child: Image.asset(
              AppBranding.splashScreenAsset,
              fit: BoxFit.contain,
              width: size.width * 0.92,
              height: size.height * 0.85,
            ),
          ),
        ),
      ),
    );
  }
}
