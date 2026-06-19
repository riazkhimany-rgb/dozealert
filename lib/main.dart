import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/monitoring_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'services/destination_storage_service.dart';
import 'services/settings_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = SettingsService();
  final destinationStorageService = DestinationStorageService();
  final monitoringProvider = MonitoringProvider(destinationStorageService);

  await monitoringProvider.loadSavedDestination();

  runApp(
    DozeAlertApp(
      settingsService: settingsService,
      destinationStorageService: destinationStorageService,
      monitoringProvider: monitoringProvider,
    ),
  );
}

class DozeAlertApp extends StatelessWidget {
  const DozeAlertApp({
    super.key,
    required this.settingsService,
    required this.destinationStorageService,
    required this.monitoringProvider,
  });

  final SettingsService settingsService;
  final DestinationStorageService destinationStorageService;
  final MonitoringProvider monitoringProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        Provider<DestinationStorageService>.value(
          value: destinationStorageService,
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(settingsService),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<MonitoringProvider>.value(
          value: monitoringProvider,
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
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
