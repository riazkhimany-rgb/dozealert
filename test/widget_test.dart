import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dozealert/main.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/providers/monitoring_provider.dart';
import 'package:dozealert/services/destination_storage_service.dart';
import 'package:dozealert/services/settings_service.dart';

Future<DozeAlertApp> _createTestApp() async {
  SharedPreferences.setMockInitialValues({});

  final settingsService = SettingsService();
  final destinationStorageService = DestinationStorageService();
  final monitoringProvider = MonitoringProvider(destinationStorageService);

  await monitoringProvider.loadSavedDestination();

  return DozeAlertApp(
    settingsService: settingsService,
    destinationStorageService: destinationStorageService,
    monitoringProvider: monitoringProvider,
  );
}

void main() {
  testWidgets('DozeAlert shows home and settings tabs', (WidgetTester tester) async {
    final app = await _createTestApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('DozeAlert'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('No destination selected'), findsOneWidget);
    expect(find.text('Choose Destination'), findsOneWidget);

    await tester.tap(find.text('Choose Destination'));
    await tester.pumpAndSettle();

    expect(find.text('Recent Destinations'), findsOneWidget);
    expect(find.text('Union Station'), findsWidgets);
    expect(find.text('Pearson Airport'), findsWidgets);

    await tester.tap(find.text('Union Station').last);
    await tester.pumpAndSettle();

    expect(find.text('Union Station'), findsOneWidget);
    expect(find.text('43.6453'), findsOneWidget);
    expect(find.text('-79.3806'), findsOneWidget);
    expect(find.text('No destination selected'), findsNothing);
    expect(find.text('Clear Destination'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Start Monitoring'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Wake-Up Radius'), findsOneWidget);
    expect(find.text('1000m'), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Start Monitoring'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
  });

  testWidgets('persists and clears selected destination', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final destinationStorageService = DestinationStorageService();
    final monitoringProvider = MonitoringProvider(destinationStorageService);

    await monitoringProvider.setDestination(
      const Destination(
        name: 'Home',
        latitude: 43.6629,
        longitude: -79.3957,
      ),
    );

    final reloadedProvider = MonitoringProvider(destinationStorageService);
    await reloadedProvider.loadSavedDestination();

    expect(reloadedProvider.selectedDestination?.name, 'Home');

    await reloadedProvider.clearDestination();

    final clearedProvider = MonitoringProvider(destinationStorageService);
    await clearedProvider.loadSavedDestination();

    expect(clearedProvider.selectedDestination, isNull);
  });
}
