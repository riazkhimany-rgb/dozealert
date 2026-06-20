import 'package:dozealert/models/destination.dart';
import 'package:dozealert/models/favorite_destination.dart';
import 'package:dozealert/models/monitoring_state.dart';
import 'package:dozealert/providers/monitoring_provider.dart';
import 'package:dozealert/services/destination_storage_service.dart';
import 'package:dozealert/services/monitoring_storage_service.dart';
import 'package:dozealert/services/onboarding_service.dart';
import 'package:dozealert/services/preferences_service.dart';
import 'package:dozealert/utils/user_facing_errors.dart';
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
}
