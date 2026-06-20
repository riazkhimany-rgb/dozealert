import 'package:flutter/material.dart';

import '../utils/app_branding.dart';
import '../widgets/branding_logo.dart';

class BrandedSplashScreen extends StatefulWidget {
  const BrandedSplashScreen({super.key});

  @override
  State<BrandedSplashScreen> createState() => _BrandedSplashScreenState();
}

class _BrandedSplashScreenState extends State<BrandedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppBranding.midnightBlue,
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: BrandingHero(
                logoHeight: 140,
                showDarkBadge: false,
                onDarkBackground: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
