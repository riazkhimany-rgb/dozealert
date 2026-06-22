import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dozealert/cache/gtfs_cache_store.dart';
import 'package:dozealert/main.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/screens/home_screen.dart';
import 'package:dozealert/providers/destination_history_provider.dart';
import 'package:dozealert/providers/gtfs_feed_provider.dart';
import 'package:dozealert/providers/gtfs_provider.dart';
import 'package:dozealert/providers/monitoring_provider.dart';
import 'package:dozealert/providers/transit_mode_provider.dart';
import 'package:dozealert/providers/transit_line_provider.dart';
import 'package:dozealert/providers/transit_provider.dart';
import 'package:dozealert/providers/trip_history_provider.dart';
import 'package:dozealert/services/alarm_service.dart';
import 'package:dozealert/services/background_monitor_service.dart';
import 'package:dozealert/services/destination_storage_service.dart';
import 'package:dozealert/services/gtfs_download_service.dart';
import 'package:dozealert/services/gtfs_import_service.dart';
import 'package:dozealert/services/gtfs_parser_service.dart';
import 'package:dozealert/services/gtfs_service.dart';
import 'package:dozealert/services/monitoring_storage_service.dart';
import 'package:dozealert/services/onboarding_service.dart';
import 'package:dozealert/services/place_search_service.dart';
import 'package:dozealert/services/preferences_service.dart';
import 'package:dozealert/services/settings_service.dart';
import 'package:dozealert/services/transit_mode_service.dart';
import 'package:dozealert/services/transit_data_service.dart';
import 'package:dozealert/services/trip_history_service.dart';
import 'package:dozealert/utils/app_branding.dart';
import 'package:dozealert/widgets/branded_app_bar_title.dart';

class _FakePathProvider {
  static void install() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  }
}

class _FakePlatformChannels {
  static void install() {
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

Future<void> _pumpUntilSettled(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  var settledFrames = 0;

  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (tester.binding.hasScheduledFrame) {
      settledFrames = 0;
      continue;
    }

    settledFrames++;
    if (settledFrames >= 2) {
      return;
    }
  }

  fail('Timed out waiting for UI to settle after $timeout');
}

Future<DozeAlertApp> _createTestApp() async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
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
    gtfsImportService,
    gtfsCacheStore,
    gtfsService,
  );
  await gtfsProvider.initialize();
  await gtfsFeedProvider.initialize();

  final tripHistoryService = TripHistoryService();
  await tripHistoryService.loadActiveTripId();

  final tripHistoryProvider = TripHistoryProvider(tripHistoryService);
  await tripHistoryProvider.load();

  final onboardingService = OnboardingService();

  return DozeAlertApp(
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
    await _pumpUntilSettled(tester);

    expect(find.byType(BrandedAppBarTitle), findsOneWidget);
    expect(find.text('Monitoring'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.textContaining('Idle'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Destination'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpUntilSettled(tester);

    expect(find.text('Destination'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.text('Set destination'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Pick where you want to wake up'),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.text('Set destination'),
      ).first,
    );
    await _pumpUntilSettled(tester);

    expect(find.text('Favorites'), findsOneWidget);

    await tester.tap(find.text('Favorites'));
    await _pumpUntilSettled(tester);

    expect(find.text('Union Station'), findsWidgets);

    await tester.tap(find.text('Union Station').last);
    await _pumpUntilSettled(tester);

    expect(find.text('Union Station'), findsWidgets);
    expect(find.text('No destination selected'), findsNothing);
    expect(find.text('Transit Settings'), findsNothing);
    expect(find.text('Train Mode'), findsNothing);
    expect(find.text('Wake-Up Radius'), findsNothing);
    expect(find.text('Distance'), findsNothing);
    expect(find.text('Recent Destinations'), findsNothing);

    await tester.tap(find.text('Trips'));
    await _pumpUntilSettled(tester);

    expect(find.text('Favorite Destinations'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Trip History'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpUntilSettled(tester);

    expect(find.text('Trip History'), findsOneWidget);
    expect(find.text('Missed Trips'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await _pumpUntilSettled(tester);

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Transit'), findsWidgets);
    expect(find.text('Location'), findsWidgets);

    await tester.tap(find.text('About'));
    await _pumpUntilSettled(tester);

    expect(find.text('About DozeAlert'), findsOneWidget);
    expect(find.text('App Version'), findsOneWidget);

    await tester.tap(find.text('About DozeAlert'));
    await _pumpUntilSettled(tester);
    expect(find.text('Share DozeAlert'), findsOneWidget);
    expect(find.text(AppBranding.tagline), findsWidgets);
    await tester.pageBack();
    await _pumpUntilSettled(tester);

    await tester.pageBack();
    await _pumpUntilSettled(tester);

    await tester.tap(
      find.text('Transit data, transit mode, and agencies'),
    );
    await _pumpUntilSettled(tester);

    expect(find.text('Transit Data'), findsOneWidget);
    expect(find.text('Transit Mode'), findsOneWidget);
    expect(find.text('Import GTFS Zip'), findsNothing);

    await tester.tap(find.text('Transit Mode'));
    await _pumpUntilSettled(tester);

    await tester.scrollUntilVisible(
      find.text('Enable Transit Mode'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpUntilSettled(tester);

    expect(find.text('Enable Transit Mode'), findsOneWidget);

    await tester.pageBack();
    await _pumpUntilSettled(tester);

    await tester.tap(find.text('Transit Data'));
    await _pumpUntilSettled(tester);

    expect(find.text('Download'), findsWidgets);
    expect(find.text('Import GTFS Zip'), findsOneWidget);

    await tester.pageBack();
    await _pumpUntilSettled(tester);
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
