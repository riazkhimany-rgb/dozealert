import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dozealert/models/destination.dart';
import 'package:dozealert/providers/monitoring_provider.dart';
import 'package:dozealert/services/destination_storage_service.dart';
import 'package:dozealert/services/monitoring_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists and clears selected destination', () async {
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
