import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../providers/navigation_provider.dart';
import 'developer_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'trips_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  List<NavigationDestination> get _destinations => [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: 'Trips',
    ),
    const NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
    if (kDebugMode)
      const NavigationDestination(
        icon: Icon(Icons.developer_mode_outlined),
        selectedIcon: Icon(Icons.developer_mode),
        label: 'Developer',
      ),
  ];

  List<Widget> get _screens => [
    const HomeScreen(),
    const TripsScreen(),
    const SettingsScreen(),
    if (kDebugMode) const DeveloperScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().resumeMonitoringIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<LocationProvider>().syncBackgroundState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<NavigationProvider>().selectedIndex;
    final safeIndex = selectedIndex.clamp(0, _screens.length - 1);

    if (safeIndex != selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NavigationProvider>().setIndex(safeIndex);
      });
    }

    return WithForegroundTask(
      child: Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: context.read<NavigationProvider>().setIndex,
          destinations: _destinations,
        ),
      ),
    );
  }
}
