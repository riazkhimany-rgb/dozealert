import 'package:flutter/material.dart';

import '../utils/app_branding.dart';
import 'branded_app_name.dart';

/// Canonical DozeAlert pin logo (from splash artwork).
///
/// On light backgrounds the pin is placed on a midnight badge so the white
/// pin body and glow remain visible.
class BrandingLogo extends StatelessWidget {
  const BrandingLogo({
    super.key,
    this.height = 96,
    this.showDarkBadge = true,
  });

  /// Logo height; width follows [AppBranding.logoAspectRatio].
  final double height;

  /// When true, renders the pin on a midnight-blue rounded badge (for light
  /// app screens). Set false on navy splash/loading backgrounds.
  final bool showDarkBadge;

  @override
  Widget build(BuildContext context) {
    final width = height * AppBranding.logoAspectRatio;
    final logo = Image.asset(
      AppBranding.splashLogoAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      semanticLabel: '${AppBranding.appName} logo',
    );

    if (!showDarkBadge) {
      return SizedBox(
        width: width,
        height: height * 1.15,
        child: Align(
          alignment: Alignment.center,
          child: Image.asset(
            AppBranding.splashLogoAsset,
            width: width,
            height: height,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            semanticLabel: '${AppBranding.appName} logo',
          ),
        ),
      );
    }

    final padding = height * 0.14;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppBranding.midnightBlue,
        borderRadius: BorderRadius.circular(height * 0.18),
        boxShadow: [
          BoxShadow(
            color: AppBranding.cyanAccent.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: padding * 0.85,
          vertical: padding,
        ),
        child: logo,
      ),
    );
  }
}

/// Logo, app name, and tagline — used on splash and about-style screens.
class BrandingHero extends StatelessWidget {
  const BrandingHero({
    super.key,
    this.logoHeight = 132,
    this.showDarkBadge = false,
    this.onDarkBackground = false,
  });

  final double logoHeight;
  final bool showDarkBadge;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = onDarkBackground
        ? AppBranding.white
        : theme.colorScheme.onSurface;
    final taglineColor = onDarkBackground
        ? AppBranding.cyanAccent
        : theme.colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandingLogo(
          height: logoHeight,
          showDarkBadge: showDarkBadge,
        ),
        SizedBox(height: logoHeight * 0.22),
        BrandedAppName(
          textAlign: TextAlign.center,
          dozeColor: titleColor,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.02,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppBranding.tagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: taglineColor,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
