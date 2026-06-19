import 'package:flutter/material.dart';

import 'app_branding.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppBranding.cyanAccent,
      brightness: Brightness.light,
      primary: AppBranding.midnightBlue,
      onPrimary: AppBranding.white,
      secondary: AppBranding.cyanAccent,
      onSecondary: AppBranding.midnightBlue,
      surface: AppBranding.white,
      onSurface: AppBranding.midnightBlue,
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppBranding.cyanAccent,
      brightness: Brightness.dark,
      primary: AppBranding.cyanAccent,
      onPrimary: AppBranding.midnightBlue,
      secondary: AppBranding.cyanAccent,
      onSecondary: AppBranding.midnightBlue,
      surface: AppBranding.midnightBlue,
      onSurface: AppBranding.white,
      surfaceContainerLow: const Color(0xFF152536),
      surfaceContainerHighest: const Color(0xFF1B3147),
    );

    return _baseTheme(colorScheme);
  }

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondary.withValues(alpha: 0.24),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: colorScheme.outlineVariant),
        selectedColor: colorScheme.secondary.withValues(alpha: 0.24),
      ),
    );
  }
}
