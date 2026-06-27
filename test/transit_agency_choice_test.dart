import 'package:dozealert/data/transit_catalog.dart';
import 'package:dozealert/models/favorite_transit_line.dart';
import 'package:dozealert/widgets/transit_agency_choice_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransitAgencyChoicePage selection model', () {
    test('toggle adds agency and sets first as primary', () {
      final selected = <String>{};
      String? primary;

      void toggle(String agency) {
        if (selected.contains(agency)) {
          selected.remove(agency);
          if (primary == agency) {
            primary = selected.isEmpty ? null : selected.first;
          }
        } else {
          selected.add(agency);
          primary ??= agency;
        }
      }

      toggle('TTC');
      expect(selected, {'TTC'});
      expect(primary, 'TTC');

      toggle('GO Transit');
      expect(selected, {'TTC', 'GO Transit'});
      expect(primary, 'TTC');

      toggle('TTC');
      expect(selected, {'GO Transit'});
      expect(primary, 'GO Transit');
    });

    test('default line favorites can represent multiple agencies', () {
      const primary = 'TTC';
      const selected = {'TTC', 'GO Transit'};

      final favorites = selected
          .map(
            (agency) => FavoriteTransitLine(
              country: TransitAgencyChoicePage.country,
              region: TransitAgencyChoicePage.region,
              transitSystem: agency,
              lineName: TransitCatalog.defaultLineForSystem(agency),
            ),
          )
          .toList();

      expect(favorites.length, 2);
      expect(
        favorites.any((line) => line.transitSystem == primary),
        isTrue,
      );
      expect(
        favorites.map((line) => line.transitSystem).toSet(),
        selected,
      );
    });
  });
}
