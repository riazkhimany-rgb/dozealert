import 'package:dozealert/utils/transit_attribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GO Transit bundled attribution includes Metrolinx credit', () {
    final text = TransitAttribution.textForAgency('GO Transit');

    expect(text, contains('GO Transit'));
    expect(text, contains('Metrolinx'));
  });

  test('list-only agencies include terms guidance', () {
    final text = TransitAttribution.textForAgency('OC Transpo');

    expect(text, contains('OC Transpo'));
    expect(text, contains('open data'));
    expect(TransitAttribution.licenseUrlForAgency('OC Transpo'), isNotNull);
  });
}
