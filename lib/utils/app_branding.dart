import 'package:flutter/material.dart';

abstract final class AppBranding {
  static const String appName = 'DozeAlert';
  static const String tagline = 'Sleep peacefully. Arrive confidently.';
  static const String description =
      'DozeAlert helps travelers wake up before reaching their '
      'destination using smart location-based alarms.';
  static const String privacyPolicyAsset = 'privacy_policy.md';
  static const String githubUrl = 'https://github.com/dozealert/dozealert';
  static const String supportEmail = 'support@dozealert.app';
  static const String privacyPolicyUrl = 'https://dozealert.app/privacy';

  static const Color midnightBlue = Color(0xFF0D1B2A);
  static const Color cyanAccent = Color(0xFF4CC9F0);
  static const Color white = Color(0xFFFFFFFF);

  static const String splashLogoAsset = 'assets/branding/splash_logo.png';
  static const String splashScreenAsset = 'assets/branding/splash_screen.png';
  static const Duration splashDisplayDuration = Duration(milliseconds: 2000);
}
