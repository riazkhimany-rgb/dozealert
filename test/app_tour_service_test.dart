import 'package:dozealert/services/app_tour_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppTourService().resetForTesting();
  });

  test('shows home tour when pending and not complete', () async {
    final service = AppTourService();
    await service.markHomeTourPending();

    expect(await service.shouldShowHomeTour(), isTrue);
  });

  test('hides home tour after completion', () async {
    final service = AppTourService();
    await service.markHomeTourPending();
    await service.markHomeTourComplete();

    expect(await service.shouldShowHomeTour(), isFalse);
  });

  test('requestReplay shows tour even when complete', () async {
    final service = AppTourService();
    await service.markHomeTourComplete();

    service.requestReplay();

    expect(await service.shouldShowHomeTour(), isTrue);
  });

  test('markHomeTourComplete clears replay request', () async {
    final service = AppTourService();
    service.requestReplay();
    await service.markHomeTourComplete();

    expect(service.replayRequested, isFalse);
    expect(await service.shouldShowHomeTour(), isFalse);
  });
}
