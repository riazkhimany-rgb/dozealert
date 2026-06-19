import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfigException implements Exception {
  EnvConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class EnvConfig {
  static const missingApiKeyMessage =
      'Google Maps API key is missing. Check .env configuration.';

  static const _googleMapsApiKeyName = 'GOOGLE_MAPS_API_KEY';

  static String get googleMapsApiKey {
    final key = dotenv.env[_googleMapsApiKeyName]?.trim();
    if (key == null || key.isEmpty) {
      throw EnvConfigException(missingApiKeyMessage);
    }
    return key;
  }

  static bool get isGoogleMapsApiKeyConfigured {
    final key = dotenv.env[_googleMapsApiKeyName]?.trim();
    return key != null && key.isNotEmpty;
  }
}
