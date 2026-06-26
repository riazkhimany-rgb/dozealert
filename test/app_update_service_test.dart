import 'package:flutter_test/flutter_test.dart';

import 'package:dozealert/models/remote_app_version.dart';
import 'package:dozealert/services/app_update_service.dart';

void main() {
  group('RemoteAppVersion', () {
    test('parses website app-version.json shape', () {
      final version = RemoteAppVersion.fromJson({
        'version': '1.0.8',
        'build': 10,
        'label': '1.0.8+10',
      });

      expect(version.version, '1.0.8');
      expect(version.build, 10);
      expect(version.displayLabel, '1.0.8+10');
      expect(version.isNewerThan(9), isTrue);
      expect(version.isNewerThan(10), isFalse);
    });
  });

  group('AppUpdateService.hasWebsiteUpdate', () {
    const remote = RemoteAppVersion(version: '1.0.8', build: 10);

    test('returns true when remote build is newer and not dismissed', () {
      expect(
        AppUpdateService.hasWebsiteUpdate(
          remote: remote,
          currentBuild: 9,
          dismissedBuild: null,
        ),
        isTrue,
      );
    });

    test('returns false when user dismissed this build', () {
      expect(
        AppUpdateService.hasWebsiteUpdate(
          remote: remote,
          currentBuild: 9,
          dismissedBuild: 10,
        ),
        isFalse,
      );
    });

    test('returns false when already on latest build', () {
      expect(
        AppUpdateService.hasWebsiteUpdate(
          remote: remote,
          currentBuild: 10,
          dismissedBuild: null,
        ),
        isFalse,
      );
    });
  });

  group('AppUpdateService.shouldUseImmediateUpdateFor', () {
    test('uses immediate update for high Play priority', () {
      expect(
        AppUpdateService.shouldUseImmediateUpdateFor(
          immediateUpdateAllowed: true,
          updatePriority: 5,
        ),
        isTrue,
      );
    });

    test('prefers flexible update for normal priority', () {
      expect(
        AppUpdateService.shouldUseImmediateUpdateFor(
          immediateUpdateAllowed: true,
          updatePriority: 2,
        ),
        isFalse,
      );
    });
  });
}
