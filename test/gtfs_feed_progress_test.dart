import 'package:dozealert/providers/gtfs_feed_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GtfsFeedProgress percent rounds overall fraction', () {
    const progress = GtfsFeedProgress(
      phase: 'Downloading…',
      overallFraction: 0.456,
    );

    expect(progress.percent, 46);
  });
}
