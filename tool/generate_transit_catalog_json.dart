import 'dart:convert';
import 'dart:io';

import 'package:dozealert/data/transit_catalog_bundled.dart';

/// Writes the bundled transit catalog to assets/ and website/.
///
/// The emitted JSON is immutable catalog metadata only:
/// - transit-catalog.json: agency discovery, feed URLs, licenses, capabilities
/// - gtfs_cache/{feedId}/feed_info.json: per-device download state (separate)
///
/// Run after editing [TransitCatalogBundled]:
///   dart run tool/generate_transit_catalog_json.dart
void main() {
  final manifest = TransitCatalogBundled.manifest.copyWith(
    generatedAt: DateTime.now().toUtc(),
  );
  final encoder = const JsonEncoder.withIndent('  ');
  final json = encoder.convert(manifest.toCatalogJson());

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
