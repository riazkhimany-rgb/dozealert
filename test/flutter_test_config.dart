import 'package:dozealert/data/transit_catalog_bundled.dart';

/// Installs the bundled transit catalog before any test reads [TransitCatalog].
Future<void> testExecutable(Future<void> Function() testMain) async {
  TransitCatalogBundled.manifest.install();
  await testMain();
}
