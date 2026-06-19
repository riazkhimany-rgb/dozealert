import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../utils/app_branding.dart';
import 'branded_splash_screen.dart';
import 'main_screen.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({
    super.key,
    this.skipSplash = false,
  });

  final bool skipSplash;

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  bool _showMainApp = false;

  @override
  void initState() {
    super.initState();
    if (widget.skipSplash) {
      _showMainApp = true;
      FlutterNativeSplash.remove();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _startSplashTimer();
  }

  Future<void> _startSplashTimer() async {
    await Future<void>.delayed(AppBranding.splashDisplayDuration);
    if (!mounted) {
      return;
    }

    setState(() {
      _showMainApp = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMainApp) {
      return const MainScreen();
    }

    return const BrandedSplashScreen();
  }
}
