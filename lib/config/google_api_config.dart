abstract final class GoogleApiConfig {
  /// Pass at build/run time:
  /// `--dart-define=GOOGLE_MAPS_API_KEY=your_key`
  ///
  /// Use the same key as `GOOGLE_MAPS_API_KEY` in `android/local.properties`.
  static const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
}
