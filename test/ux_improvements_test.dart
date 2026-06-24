import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/app_permission_snapshot.dart';
import 'package:dozealert/models/destination.dart';
import 'package:dozealert/models/favorite_transit_line.dart';
import 'package:dozealert/models/favorite_destination.dart';
import 'package:dozealert/models/monitoring_state.dart';
import 'package:dozealert/providers/monitoring_provider.dart';
import 'package:dozealert/services/destination_storage_service.dart';
import 'package:dozealert/services/monitoring_storage_service.dart';
import 'package:dozealert/services/onboarding_service.dart';
import 'package:dozealert/services/preferences_service.dart';
import 'package:dozealert/utils/user_facing_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('PreferencesService seeds favorites once', () async {
    SharedPreferences.setMockInitialValues({});

    final preferencesService = PreferencesService();
    final first = await preferencesService.seedFavoritesIfEmpty();
    final second = await preferencesService.seedFavoritesIfEmpty();

    expect(first, isNotEmpty);
    expect(second.length, first.length);
  });

  test('PreferencesService persists favorites add and remove', () async {
    SharedPreferences.setMockInitialValues({});

    final preferencesService = PreferencesService();
    const destination = Destination(
      name: 'Test Stop',
      latitude: 43.0,
      longitude: -79.0,
    );

    final added = await preferencesService.addFavorite(
      FavoriteDestination(destination: destination, badges: ['Home']),
    );
    expect(added.length, 1);

    final removed = await preferencesService.removeFavorite(destination);
    expect(removed, isEmpty);
  });

  test('PreferencesService persists favorite transit lines add and remove', () async {
    SharedPreferences.setMockInitialValues({});

    const favorite = FavoriteTransitLine(
      country: 'Canada',
      region: 'Ontario',
      transitSystem: 'TTC',
      lineName: 'Line 1',
    );

    final preferencesService = PreferencesService();
    final added = await preferencesService.addFavoriteTransitLine(favorite);
    expect(added, hasLength(1));
    expect(added.first.label, 'TTC · Line 1');

    final duplicate = await preferencesService.addFavoriteTransitLine(favorite);
    expect(duplicate, hasLength(1));

    final removed = await preferencesService.removeFavoriteTransitLine(favorite);
    expect(removed, isEmpty);
  });

  test('PreferencesService loads empty favorite transit lines by default', () async {
    SharedPreferences.setMockInitialValues({});

    final preferencesService = PreferencesService();
    expect(await preferencesService.loadFavoriteTransitLines(), isEmpty);
  });

  test('AppPermissionSnapshot detects incomplete monitoring permissions', () {
    const snapshot = AppPermissionSnapshot(
      locationWhenInUseGranted: false,
      backgroundLocationGranted: false,
      notificationsGranted: false,
      locationServicesEnabled: true,
      batteryOptimizationEnabled: true,
    );

    expect(snapshot.allRequiredForMonitoring, isFalse);
    expect(snapshot.batteryUnrestricted, isFalse);
    expect(snapshot.missingRequiredLabels, isNotEmpty);
  });

  test('OnboardingService tracks completion and alarm test', () async {
    SharedPreferences.setMockInitialValues({});

    final service = OnboardingService();
    expect(await service.isComplete(), isFalse);
    expect(await service.isAlarmTested(), isFalse);

    await service.markAlarmTested();
    await service.markComplete();

    expect(await service.isAlarmTested(), isTrue);
    expect(await service.isComplete(), isTrue);
  });

  test('MonitoringProvider marks missed state', () async {
    final provider = MonitoringProvider(
      DestinationStorageService(),
      MonitoringStorageService(),
    );

    await provider.setDestination(
      const Destination(
        name: 'Union Station',
        latitude: 43.6453,
        longitude: -79.3806,
      ),
    );
    provider.startMonitoring();
    provider.markMissed();

    expect(provider.currentState, MonitoringState.missed);
  });

  test('UserFacingErrors maps network failures', () {
    expect(
      UserFacingErrors.from(Exception('SocketException: Failed host lookup')),
      contains('network'),
    );
  });

  test('TransitCatalog maps device locale to transit defaults', () {
    final canada = TransitCatalog.preferencesForLocale(const Locale('en', 'CA'));
    expect(canada.country, 'Canada');
    expect(canada.region, 'Ontario');

    final us = TransitCatalog.preferencesForLocale(const Locale('en', 'US'));
    expect(us.country, 'United States');
    expect(us.region, 'New York');
  });
}
