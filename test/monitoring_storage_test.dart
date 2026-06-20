import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dozealert/models/monitoring_state.dart';
import 'package:dozealert/services/monitoring_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MonitoringStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = MonitoringStorageService();
  });

  test('clearSession removes monitoring start timestamp', () async {
    await storage.markMonitoringStarted(
      DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
    );
    await storage.saveSession(
      isActive: true,
      state: MonitoringState.monitoring,
      radiusMeters: 1000,
    );

    await storage.clearSession();

    expect(await storage.loadMonitoringStartedAt(), isNull);
    expect(await storage.isArrivalTriggered(), isFalse);
    expect(await storage.isMonitoringActive(), isFalse);
  });
}
