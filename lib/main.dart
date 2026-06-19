import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'providers/location_provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/app_startup_screen.dart';
import 'services/alarm_service.dart';
import 'services/destination_storage_service.dart';
import 'services/location_service.dart';
import 'services/settings_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final settingsService = SettingsService();
  await settingsService.loadSettings();

  final alarmService = AlarmService();
  await alarmService.initialize();

  final destinationStorageService = DestinationStorageService();
  final monitoringProvider = MonitoringProvider(destinationStorageService);

  await monitoringProvider.loadSavedDestination();

  runApp(
    DozeAlertApp(
      settingsService: settingsService,
      alarmService: alarmService,
      destinationStorageService: destinationStorageService,
      monitoringProvider: monitoringProvider,
    ),
  );
}

class DozeAlertApp extends StatelessWidget {
  const DozeAlertApp({
    super.key,
    required this.settingsService,
    required this.alarmService,
    required this.destinationStorageService,
    required this.monitoringProvider,
    this.skipSplash = false,
  });

  final SettingsService settingsService;
  final AlarmService alarmService;
  final DestinationStorageService destinationStorageService;
  final MonitoringProvider monitoringProvider;
  final bool skipSplash;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        Provider<AlarmService>.value(value: alarmService),
        Provider<DestinationStorageService>.value(
          value: destinationStorageService,
        ),
        Provider<LocationService>(
          create: (_) => LocationService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(settingsService),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsService),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<MonitoringProvider>.value(
          value: monitoringProvider,
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider(
            context.read<LocationService>(),
            monitoringProvider,
            alarmService,
            settingsService,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'DozeAlert',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            home: AppStartupScreen(skipSplash: skipSplash),
          );
        },
      ),
    );
  }
}
