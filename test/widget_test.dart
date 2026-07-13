import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/main.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/screens/home_screen.dart';
import 'package:dozealert/providers/favorite_transit_line_provider.dart';
import 'package:dozealert/providers/destination_history_provider.dart';
import 'package:dozealert/providers/gtfs_feed_provider.dart';
import 'package:dozealert/providers/gtfs_provider.dart';
import 'package:dozealert/providers/monitoring_provider.dart';
import 'package:dozealert/providers/transit_mode_provider.dart';
import 'package:dozealert/providers/transit_provider.dart';
import 'package:dozealert/providers/trip_history_provider.dart';
import 'package:dozealert/services/activity_recognition_service.dart';
import 'package:dozealert/utils/trip_ux_copy.dart';
import 'package:dozealert/services/alarm_service.dart';
import 'package:dozealert/services/background_monitor_service.dart';
import 'package:dozealert/services/destination_storage_service.dart';
import 'package:dozealert/services/gtfs_download_service.dart';
import 'package:dozealert/services/gtfs_import_service.dart';
import 'package:dozealert/services/gtfs_parser_service.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/monitoring_storage_service.dart';
import 'package:dozealert/services/app_tour_service.dart';
import 'package:dozealert/services/onboarding_service.dart';
import 'package:dozealert/services/place_search_service.dart';
import 'package:dozealert/services/preferences_service.dart';
import 'package:dozealert/services/settings_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';
import 'package:dozealert/services/transit_catalog_store.dart';
import 'package:dozealert/services/trip_history_service.dart';
import 'package:dozealert/widgets/branded_app_bar_title.dart';

class _FakePathProvider {
  static String? _documentsPath;

  static void install() {
    _documentsPath =
        '${Directory.systemTemp.path}/dozealert_test_${DateTime.now().microsecondsSinceEpoch}';
    Directory(_documentsPath!).createSync(recursive: true);

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return _documentsPath;
      }
      return null;
    });
  }
}

class _FakePlatformChannels {
  static void install() {
    const packageInfoChannel =
        MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (call) async {
      return {
        'appName': 'DozeAlert',
        'packageName': 'app.dozealert',
        'version': '1.1.0',
        'buildNumber': '41',
      };
    });

    const geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        default:
          return null;
      }
    });

    const permissionsChannel =
        MethodChannel('flutter.baseflow.com/permissions/methods');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionsChannel, (call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
        case 'checkServiceStatus':
          return 0;
        default:
          return 0;
      }
    });
  }
}

Future<void> _pumpUi(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 300),
}) async {
  await tester.pump();
  await tester.pump(duration);
}

Future<DozeAlertApp> _createTestApp() async {
  SharedPreferences.setMockInitialValues({
    'onboarding_complete': true,
    'home_tour_complete': true,
  });
  dotenv.loadFromString(envString: 'GOOGLE_MAPS_API_KEY=test_key');

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
  final catalogStore = TransitCatalogStore();
  await catalogStore.initialize();
  final gtfsCacheStore = GtfsCacheStore();
  final gtfsParserService = GtfsParserService();
  final gtfsDownloadService = GtfsDownloadService();
  final gtfsImportService = GtfsImportService(gtfsCacheStore, gtfsParserService);
  final gtfsService = GtfsService();
  final transitProvider = TransitProvider(preferencesService);
  await transitProvider.loadPreferences();

  final destinationHistoryProvider =
      DestinationHistoryProvider(preferencesService);
  await destinationHistoryProvider.load();
  await destinationHistoryProvider.addFavorite(
    const Destination(
      name: 'Union Station',
      latitude: 43.6453,
      longitude: -79.3806,
    ),
    badges: ['GO Transit · Lakeshore West'],
  );

  final favoriteTransitLineProvider =
      FavoriteTransitLineProvider(preferencesService);
  await favoriteTransitLineProvider.load();

  final monitoringProvider = MonitoringProvider(
    destinationStorageService,
    monitoringStorageService,
    destinationHistory: destinationHistoryProvider,
  );

  await monitoringProvider.loadSavedDestination();
  await monitoringProvider.loadMonitoringSession();

  final transitModeService = TransitModeService(gtfsService);
  final activityRecognitionService = ActivityRecognitionService(settingsService);
  final transitModeProvider = TransitModeProvider(
    transitModeService,
    settingsService,
    monitoringProvider,
    monitoringStorageService,
    activityRecognitionService,
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
    gtfsImportService,
    gtfsCacheStore,
    gtfsService,
  );
  gtfsFeedProvider.onFeedsChanged = gtfsProvider.onFeedDataChanged;
  // GTFS seed init is lightweight; skip feed hydration in widget tests.
  await gtfsFeedProvider.initialize();

  final tripHistoryService = TripHistoryService();
  await tripHistoryService.loadActiveTripId();

  final tripHistoryProvider = TripHistoryProvider(tripHistoryService);
  await tripHistoryProvider.load();

  final onboardingService = OnboardingService();
  final appTourService = AppTourService();

  return DozeAlertApp(
    settingsService: settingsService,
    alarmService: alarmService,
    backgroundMonitorService: backgroundMonitorService,
    monitoringStorageService: monitoringStorageService,
    placeSearchService: placeSearchService,
    preferencesService: preferencesService,
    gtfsService: gtfsService,
    gtfsCacheStore: gtfsCacheStore,
    gtfsDownloadService: gtfsDownloadService,
    gtfsParserService: gtfsParserService,
    gtfsImportService: gtfsImportService,
    transitProvider: transitProvider,
    transitModeProvider: transitModeProvider,
    gtfsProvider: gtfsProvider,
    gtfsFeedProvider: gtfsFeedProvider,
    destinationStorageService: destinationStorageService,
    monitoringProvider: monitoringProvider,
    destinationHistoryProvider: destinationHistoryProvider,
    favoriteTransitLineProvider: favoriteTransitLineProvider,
    tripHistoryService: tripHistoryService,
    tripHistoryProvider: tripHistoryProvider,
      onboardingService: onboardingService,
      appTourService: appTourService,
      activityRecognitionService: activityRecognitionService,
      catalogStore: catalogStore,
    skipSplash: true,
    skipBootstrap: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _FakePathProvider.install();
  _FakePlatformChannels.install();

  testWidgets('DozeAlert shows simplified home and navigation tabs', (
    WidgetTester tester,
  ) async {
    final app = await _createTestApp();
    await tester.pumpWidget(app);
    await _pumpUi(tester);

    expect(find.byType(BrandedAppBarTitle), findsOneWidget);
    expect(find.text('Your trip'), findsOneWidget);
    expect(find.text('Pick your stop'), findsWidgets);

    expect(find.text(TripUxCopy.emptyHeadline), findsOneWidget);

    await tester.tap(find.text(TripUxCopy.myTripsTab));
    await _pumpUi(tester);

    await tester.tap(find.text('Union Station'));
    await _pumpUi(tester);

    await tester.tap(find.text('Home'));
    await _pumpUi(tester);

    expect(find.text('Union Station'), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.text('Start'),
      ),
      findsOneWidget,
    );
    expect(find.text('No destination selected'), findsNothing);
    expect(find.text('Transit Settings'), findsNothing);
    expect(find.text('Train Mode'), findsNothing);
    expect(find.text('Wake-Up Radius'), findsNothing);
    expect(find.text('Distance'), findsNothing);
    expect(find.text('Recent Destinations'), findsNothing);

    await tester.tap(find.text('My Trips'));
    await _pumpUi(tester);

    expect(find.text('Saved stops'), findsOneWidget);
    expect(find.text('Trip History'), findsNothing);
    expect(find.text('Missed Trips'), findsNothing);

    await tester.tap(find.text('Settings'));
    await _pumpUi(tester);

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);
    expect(find.text('About'), findsWidgets);
  });

  testWidgets('persists and clears selected destination', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final destinationStorageService = DestinationStorageService();
    final monitoringStorageService = MonitoringStorageService();
    final monitoringProvider = MonitoringProvider(
      destinationStorageService,
      monitoringStorageService,
    );

    await monitoringProvider.setDestination(
      const Destination(
        name: 'Home',
        latitude: 43.6629,
        longitude: -79.3957,
      ),
    );

    final reloadedProvider = MonitoringProvider(
      destinationStorageService,
      monitoringStorageService,
    );
    await reloadedProvider.loadSavedDestination();

    expect(reloadedProvider.selectedDestination?.name, 'Home');

    await reloadedProvider.clearDestination();

    final clearedProvider = MonitoringProvider(
      destinationStorageService,
      monitoringStorageService,
    );
    await clearedProvider.loadSavedDestination();

    expect(clearedProvider.selectedDestination, isNull);
  });

  test('persists wake radius without an active monitoring session', () async {
    SharedPreferences.setMockInitialValues({});

    final monitoringStorageService = MonitoringStorageService();
    final monitoringProvider = MonitoringProvider(
      DestinationStorageService(),
      monitoringStorageService,
    );

    await monitoringProvider.setRadius(250);

    final reloadedProvider = MonitoringProvider(
      DestinationStorageService(),
      monitoringStorageService,
    );
    await reloadedProvider.loadMonitoringSession();

    expect(reloadedProvider.radiusMeters, 250);
  });
}
