import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

import '../config/google_api_config.dart';
import '../models/destination.dart';
import '../utils/map_defaults.dart';

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  LatLng get latLng => LatLng(latitude, longitude);

  Destination toDestination() {
    return Destination(
      name: name,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class PlaceSearchService {
  PlaceSearchService({String? apiKey}) : _apiKey = apiKey ?? GoogleApiConfig.apiKey;

  final String _apiKey;

  static const searchPlaceholder = 'Search destination';

  static const exampleSearches = <String>[
    'Bronte GO',
    'Milton GO',
    'Pearson Airport',
    'CN Tower',
  ];

  bool get isConfigured => _apiKey.isNotEmpty;

  String get apiKey => _apiKey;

  String get searchHelperText => 'Examples: ${exampleSearches.join(', ')}';

  PlaceSearchResult? parsePrediction(Prediction prediction) {
    final latitude = double.tryParse(prediction.lat ?? '');
    final longitude = double.tryParse(prediction.lng ?? '');
    if (latitude == null || longitude == null) {
      return null;
    }

    return PlaceSearchResult(
      name: displayName(prediction),
      latitude: latitude,
      longitude: longitude,
    );
  }

  String displayName(Prediction prediction) {
    final mainText = prediction.structuredFormatting?.mainText?.trim();
    if (mainText != null && mainText.isNotEmpty) {
      return mainText;
    }

    final description = prediction.description?.trim();
    if (description == null || description.isEmpty) {
      return MapDefaults.customDestinationName;
    }

    return description.split(',').first.trim();
  }
}
