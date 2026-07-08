import 'package:dozealert/utils/transit_attribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GO Transit bundled attribution includes Metrolinx credit', () {
    final text = TransitAttribution.textForAgency('GO Transit');

    expect(text, contains('GO Transit'));
    expect(text, contains('Metrolinx'));
  });

  test('OC Transpo uses catalog feed attribution', () {
    final text = TransitAttribution.textForAgency('OC Transpo');

    expect(text, contains('OC Transpo'));
    expect(text, contains('Open Government Licence'));
    expect(
      TransitAttribution.licenseUrlForAgency('OC Transpo'),
      'https://www.octranspo.com/en/plan-your-trip/travel-tools/developers/dev-terms',
    );
    expect(
      TransitAttribution.feedForAgency('OC Transpo')?.hasDirectDownload,
      isTrue,
    );
  });

  test('list-only agencies include terms guidance', () {
    final text = TransitAttribution.textForAgency('STM Montreal');

    expect(text, contains('STM'));
    expect(text, contains('open data'));
    expect(TransitAttribution.licenseUrlForAgency('STM Montreal'), isNotNull);
  });
}
