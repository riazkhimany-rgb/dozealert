import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dozealert/main.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/providers/monitoring_provider.dart';
import 'package:dozealert/services/alarm_service.dart';
import 'package:dozealert/services/background_monitor_service.dart';
import 'package:dozealert/services/destination_storage_service.dart';
import 'package:dozealert/services/monitoring_storage_service.dart';
import 'package:dozealert/services/place_search_service.dart';
import 'package:dozealert/services/settings_service.dart';

Future<DozeAlertApp> _createTestApp() async {
  SharedPreferences.setMockInitialValues({});

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
  final monitoringProvider = MonitoringProvider(
    destinationStorageService,
    monitoringStorageService,
  );

  await monitoringProvider.loadSavedDestination();
  await monitoringProvider.loadMonitoringSession();

  return DozeAlertApp(
    settingsService: settingsService,
    alarmService: alarmService,
    backgroundMonitorService: backgroundMonitorService,
    monitoringStorageService: monitoringStorageService,
    placeSearchService: placeSearchService,
    destinationStorageService: destinationStorageService,
    monitoringProvider: monitoringProvider,
    skipSplash: true,
  );
}

void main() {
  testWidgets('DozeAlert shows home and settings tabs', (WidgetTester tester) async {
    final app = await _createTestApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('DozeAlert'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('No destination selected'), findsWidgets);
    expect(find.text('Choose Destination'), findsOneWidget);
    expect(find.text('Change Destination'), findsOneWidget);

    await tester.tap(find.text('Choose Destination'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Search on Map'), findsOneWidget);
    expect(find.text('Bronte GO'), findsOneWidget);
    expect(find.text('Union Station'), findsWidgets);

    await tester.tap(find.text('Union Station').last);
    await tester.pumpAndSettle();

    expect(find.text('Union Station'), findsOneWidget);
    expect(find.text('43.6453'), findsOneWidget);
    expect(find.text('-79.3806'), findsOneWidget);
    expect(find.text('No destination selected'), findsNothing);
    expect(find.text('Clear Destination'), findsOneWidget);
    expect(find.text('Monitoring Status'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Start Monitoring'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Wake-Up Radius'), findsOneWidget);
    expect(find.text('1000m'), findsOneWidget);
    expect(find.text('Idle'), findsWidgets);
    expect(find.text('Start Monitoring'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Developer Settings'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('About DozeAlert'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('About DozeAlert'), findsOneWidget);

    await tester.tap(find.text('About DozeAlert'));
    await tester.pumpAndSettle();

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Sleep peacefully. Arrive confidently.'), findsWidgets);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('GitHub Repository'), findsOneWidget);
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
}
