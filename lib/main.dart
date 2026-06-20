import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'providers/destination_history_provider.dart';
import 'providers/gtfs_feed_provider.dart';
import 'providers/gtfs_provider.dart';
import 'providers/location_provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transit_mode_provider.dart';
import 'providers/transit_line_provider.dart';
import 'providers/trip_history_provider.dart';
import 'providers/transit_provider.dart';
import 'screens/app_startup_screen.dart';
import 'cache/gtfs_cache_store.dart';
import 'services/alarm_service.dart';
import 'services/background_monitor_service.dart';
import 'services/destination_storage_service.dart';
import 'services/developer_diagnostics_service.dart';
import 'services/gtfs_download_service.dart';
import 'services/gtfs_import_service.dart';
import 'services/gtfs_parser_service.dart';
import 'services/gtfs_service.dart';
import 'services/location_service.dart';
import 'services/monitoring_storage_service.dart';
import 'services/onboarding_service.dart';
import 'services/place_search_service.dart';
import 'services/preferences_service.dart';
import 'services/settings_service.dart';
import 'services/transit_mode_service.dart';
import 'services/transit_data_service.dart';
import 'services/trip_history_service.dart';
import 'utils/app_log.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await _loadEnvironment();

  final settingsService = SettingsService();
  await settingsService.loadSettings();

  final alarmService = AlarmService(settingsService);
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
  final gtfsParserService = GtfsParserService();
  final gtfsDownloadService = GtfsDownloadService();
  final gtfsImportService = GtfsImportService(gtfsCacheStore, gtfsParserService);
  final gtfsService = GtfsService(transitDataService);
  final transitProvider = TransitProvider(preferencesService);
  await transitProvider.loadPreferences();

  final destinationHistoryProvider =
      DestinationHistoryProvider(preferencesService);
  await destinationHistoryProvider.load();

  final monitoringProvider = MonitoringProvider(
    destinationStorageService,
    monitoringStorageService,
    destinationHistory: destinationHistoryProvider,
  );

  await monitoringProvider.loadSavedDestination();
  await monitoringProvider.loadMonitoringSession();

  final transitLineProvider = TransitLineProvider(
    transitDataService,
    transitProvider,
    monitoringProvider,
  );
  await transitLineProvider.loadCurrentLine();

  final transitModeService = TransitModeService(gtfsService);
  final transitModeProvider = TransitModeProvider(
    transitModeService,
    settingsService,
    monitoringProvider,
  );
  final gtfsProvider = GtfsProvider(
    gtfsService,
    gtfsImportService,
    transitProvider,
    monitoringProvider,
    transitModeProvider,
  );

  final gtfsFeedProvider = GtfsFeedProvider(
    gtfsDownloadService,
    gtfsParserService,
    gtfsImportService,
    gtfsCacheStore,
    gtfsService,
  );

  final tripHistoryService = TripHistoryService();
  await tripHistoryService.loadActiveTripId();

  final tripHistoryProvider = TripHistoryProvider(tripHistoryService);
  await tripHistoryProvider.load();

  final onboardingService = OnboardingService();

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
      gtfsDownloadService: gtfsDownloadService,
      gtfsParserService: gtfsParserService,
      gtfsImportService: gtfsImportService,
      transitProvider: transitProvider,
      transitLineProvider: transitLineProvider,
      transitModeProvider: transitModeProvider,
      gtfsProvider: gtfsProvider,
      gtfsFeedProvider: gtfsFeedProvider,
      destinationStorageService: destinationStorageService,
      monitoringProvider: monitoringProvider,
      destinationHistoryProvider: destinationHistoryProvider,
      tripHistoryService: tripHistoryService,
      tripHistoryProvider: tripHistoryProvider,
      onboardingService: onboardingService,
    ),
  );
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    AppLog.d('Failed to load .env: $error');
    AppLog.d('$stackTrace');
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
    required this.gtfsDownloadService,
    required this.gtfsParserService,
    required this.gtfsImportService,
    required this.transitProvider,
    required this.transitLineProvider,
    required this.transitModeProvider,
    required this.gtfsProvider,
    required this.gtfsFeedProvider,
    required this.destinationStorageService,
    required this.monitoringProvider,
    required this.destinationHistoryProvider,
    required this.tripHistoryService,
    required this.tripHistoryProvider,
    required this.onboardingService,
    this.skipSplash = false,
    this.skipBootstrap = false,
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
  final GtfsDownloadService gtfsDownloadService;
  final GtfsParserService gtfsParserService;
  final GtfsImportService gtfsImportService;
  final TransitProvider transitProvider;
  final TransitLineProvider transitLineProvider;
  final TransitModeProvider transitModeProvider;
  final GtfsProvider gtfsProvider;
  final GtfsFeedProvider gtfsFeedProvider;
  final DestinationStorageService destinationStorageService;
  final MonitoringProvider monitoringProvider;
  final DestinationHistoryProvider destinationHistoryProvider;
  final TripHistoryService tripHistoryService;
  final TripHistoryProvider tripHistoryProvider;
  final OnboardingService onboardingService;
  final bool skipSplash;
  final bool skipBootstrap;

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
        Provider<GtfsDownloadService>.value(value: gtfsDownloadService),
        Provider<GtfsParserService>.value(value: gtfsParserService),
        Provider<GtfsImportService>.value(value: gtfsImportService),
        Provider<TripHistoryService>.value(value: tripHistoryService),
        Provider<OnboardingService>.value(value: onboardingService),
        Provider<DestinationStorageService>.value(
          value: destinationStorageService,
        ),
        Provider<LocationService>(
          create: (_) => LocationService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<DeveloperDiagnosticsService>(
          create: (context) => DeveloperDiagnosticsService(
            context.read<LocationService>(),
            context.read<BackgroundMonitorService>(),
            context.read<AlarmService>(),
            context.read<TripHistoryService>(),
          ),
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
        ChangeNotifierProvider<TransitModeProvider>.value(
          value: transitModeProvider,
        ),
        ChangeNotifierProvider<GtfsProvider>.value(
          value: gtfsProvider,
        ),
        ChangeNotifierProvider<GtfsFeedProvider>.value(
          value: gtfsFeedProvider,
        ),
        ChangeNotifierProvider<DestinationHistoryProvider>.value(
          value: destinationHistoryProvider,
        ),
        ChangeNotifierProvider<TripHistoryProvider>.value(
          value: tripHistoryProvider,
        ),
        ChangeNotifierProvider(
          create: (context) => LocationProvider(
            context.read<LocationService>(),
            monitoringProvider,
            alarmService,
            settingsService,
            backgroundMonitorService,
            monitoringStorageService,
            transitModeProvider,
            context.read<TripHistoryService>(),
            tripHistoryProvider: tripHistoryProvider,
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
            home: AppStartupScreen(
              skipSplash: skipSplash,
              skipBootstrap: skipBootstrap,
            ),
          );
        },
      ),
    );
  }
}
