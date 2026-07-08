import 'dart:convert';
import 'dart:io';

import 'package:dozealert/data/transit_catalog_bundled.dart';

/// Writes the bundled transit catalog to assets/ and website/.
///
/// Run after editing [TransitCatalogBundled]:
///   dart run tool/generate_transit_catalog_json.dart
void main() {
  final manifest = TransitCatalogBundled.manifest;
  final encoder = const JsonEncoder.withIndent('  ');
  final json = encoder.convert(manifest.toJson());

  final targets = <String>[
    'assets/transit-catalog.json',
    'website/transit-catalog/transit-catalog.json',
  ];

  for (final path in targets) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('$json\n');
    stdout.writeln('Wrote $path');
  }
}
