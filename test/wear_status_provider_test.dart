import 'package:dozealert/providers/wear_status_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WearStatusProvider', () {
    test('hides connected state when watch app is not installed', () {
      final provider = WearStatusProvider();

      provider.setWearStatus(appInstalled: false, connected: true);

      expect(provider.hasChecked, isTrue);
      expect(provider.appInstalled, isFalse);
      expect(provider.watchConnected, isFalse);
    });

    test('reports green only when installed and reachable', () {
      final provider = WearStatusProvider();

      provider.setWearStatus(appInstalled: true, connected: true);
      expect(provider.watchConnected, isTrue);

      provider.setWearStatus(appInstalled: true, connected: false);
      expect(provider.watchConnected, isFalse);
    });
  });
}
