import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'providers/gtfs_provider.dart';
import 'providers/location_provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/train_mode_provider.dart';
import 'providers/transit_line_provider.dart';
import 'providers/transit_provider.dart';
import 'screens/app_startup_screen.dart';
import 'cache/gtfs_cache_store.dart';
import 'services/alarm_service.dart';
import 'services/background_monitor_service.dart';
import 'services/destination_storage_service.dart';
import 'services/gtfs_import_service.dart';
import 'services/gtfs_service.dart';
import 'services/location_service.dart';
import 'services/monitoring_storage_service.dart';
import 'services/place_search_service.dart';
import 'services/preferences_service.dart';
import 'services/settings_service.dart';
import 'services/train_mode_service.dart';
import 'services/transit_data_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await _loadEnvironment();

  final settingsService = SettingsService();
  await settingsService.loadSettings();

  final alarmService = AlarmService();
  await alarmService.initialize();

  final destinationStorageService = DestinationStorageService();
  final monitoringStorageService = MonitoringStorageService();
  final backgroundMonitorService =
      BackgroundMonitorService(monitoringStorageService);
  await backgroundMonitorService.initialize();

  final placeSearchService = PlaceSearchService();
  final preferencesService = PreferencesService();
  final transitDataService = TransitDataService();
  final gtfsCacheStore = GtfsCacheStore();
  final gtfsImportService = GtfsImportService(gtfsCacheStore);
  final gtfsService = GtfsService(transitDataService);
  final transitProvider = TransitProvider(preferencesService);
  await transitProvider.loadPreferences();

  final monitoringProvider = MonitoringProvider(
    destinationStorageService,
    monitoringStorageService,
  );

  await monitoringProvider.loadSavedDestination();
  await monitoringProvider.loadMonitoringSession();

  final transitLineProvider = TransitLineProvider(
    transitDataService,
    transitProvider,
    monitoringProvider,
  );
  await transitLineProvider.loadCurrentLine();

  final trainModeService = TrainModeService(gtfsService);
  final trainModeProvider = TrainModeProvider(
    trainModeService,
    settingsService,
    monitoringProvider,
  );
  final gtfsProvider = GtfsProvider(
    gtfsService,
    gtfsImportService,
    transitProvider,
    monitoringProvider,
    trainModeProvider,
  );
  await gtfsProvider.initialize();

  runApp(
    DozeAlertApp(
      settingsService: settingsService,
      alarmService: alarmService,
      backgroundMonitorService: backgroundMonitorService,
      monitoringStorageService: monitoringStorageService,
      placeSearchService: placeSearchService,
      preferencesService: preferencesService,
      transitDataService: transitDataService,
      gtfsService: gtfsService,
      gtfsCacheStore: gtfsCacheStore,
      gtfsImportService: gtfsImportService,
      transitProvider: transitProvider,
      transitLineProvider: transitLineProvider,
      trainModeProvider: trainModeProvider,
      gtfsProvider: gtfsProvider,
      destinationStorageService: destinationStorageService,
      monitoringProvider: monitoringProvider,
    ),
  );
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    debugPrint('Failed to load .env: $error');
    debugPrint('$stackTrace');
    dotenv.loadFromString(
      envString: 'GOOGLE_MAPS_API_KEY=',
      isOptional: true,
    );
  }
}

class DozeAlertApp extends StatelessWidget {
  const DozeAlertApp({
    super.key,
    required this.settingsService,
    required this.alarmService,
    required this.backgroundMonitorService,
    required this.monitoringStorageService,
    required this.placeSearchService,
    required this.preferencesService,
    required this.transitDataService,
    required this.gtfsService,
    required this.gtfsCacheStore,
    required this.gtfsImportService,
    required this.transitProvider,
    required this.transitLineProvider,
    required this.trainModeProvider,
    required this.gtfsProvider,
    required this.destinationStorageService,
    required this.monitoringProvider,
    this.skipSplash = false,
  });

  final SettingsService settingsService;
  final AlarmService alarmService;
  final BackgroundMonitorService backgroundMonitorService;
  final MonitoringStorageService monitoringStorageService;
  final PlaceSearchService placeSearchService;
  final PreferencesService preferencesService;
  final TransitDataService transitDataService;
  final GtfsService gtfsService;
  final GtfsCacheStore gtfsCacheStore;
  final GtfsImportService gtfsImportService;
  final TransitProvider transitProvider;
  final TransitLineProvider transitLineProvider;
  final TrainModeProvider trainModeProvider;
  final GtfsProvider gtfsProvider;
  final DestinationStorageService destinationStorageService;
  final MonitoringProvider monitoringProvider;
  final bool skipSplash;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsService>.value(value: settingsService),
        Provider<AlarmService>.value(value: alarmService),
        Provider<BackgroundMonitorService>.value(
          value: backgroundMonitorService,
        ),
        Provider<MonitoringStorageService>.value(
          value: monitoringStorageService,
        ),
        Provider<PlaceSearchService>.value(value: placeSearchService),
        Provider<PreferencesService>.value(value: preferencesService),
        Provider<TransitDataService>.value(value: transitDataService),
        Provider<GtfsService>.value(value: gtfsService),
        Provider<GtfsCacheStore>.value(value: gtfsCacheStore),
        Provider<GtfsImportService>.value(value: gtfsImportService),
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
        ChangeNotifierProvider<TransitProvider>.value(
          value: transitProvider,
        ),
        ChangeNotifierProvider<TransitLineProvider>.value(
          value: transitLineProvider,
        ),
        ChangeNotifierProvider<TrainModeProvider>.value(
          value: trainModeProvider,
        ),
        ChangeNotifierProvider<GtfsProvider>.value(
          value: gtfsProvider,
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider(
            context.read<LocationService>(),
            monitoringProvider,
            alarmService,
            settingsService,
            backgroundMonitorService,
            monitoringStorageService,
            trainModeProvider,
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
