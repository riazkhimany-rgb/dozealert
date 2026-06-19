import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/transit_catalog.dart';
import '../models/destination.dart';
import '../models/transit_preferences.dart';

class PreferencesService {
  static const _countryKey = 'transit_country';
  static const _regionKey = 'transit_region';
  static const _transitSystemKey = 'transit_system';
  static const _defaultLineKey = 'transit_default_line';
  static const _recentStationsKey = 'transit_recent_stations';
  static const _maxRecentStations = 8;

  Future<TransitPreferences> loadTransitPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString(_countryKey);
    final region = prefs.getString(_regionKey);
    final transitSystem = prefs.getString(_transitSystemKey);
    final defaultLine = prefs.getString(_defaultLineKey);

    if (country == null || transitSystem == null || defaultLine == null) {
      return TransitPreferences.defaults;
    }

    return TransitCatalog.normalize(
      TransitPreferences(
        country: country,
        region: region ?? TransitCatalog.defaultRegionForCountry(country),
        transitSystem: transitSystem,
        defaultLine: defaultLine,
      ),
    );
  }

  Future<void> saveTransitPreferences(TransitPreferences preferences) async {
    final normalized = TransitCatalog.normalize(preferences);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, normalized.country);
    await prefs.setString(_regionKey, normalized.region);
    await prefs.setString(_transitSystemKey, normalized.transitSystem);
    await prefs.setString(_defaultLineKey, normalized.defaultLine);
  }

  Future<List<Destination>> loadRecentStations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentStationsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) {
            final map = entry as Map<String, dynamic>;
            return Destination(
              name: map['name'] as String,
              latitude: (map['latitude'] as num).toDouble(),
              longitude: (map['longitude'] as num).toDouble(),
            );
          })
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveRecentStations(List<Destination> stations) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      stations
          .map(
            (station) => {
              'name': station.name,
              'latitude': station.latitude,
              'longitude': station.longitude,
            },
          )
          .toList(growable: false),
    );
    await prefs.setString(_recentStationsKey, encoded);
  }

  Future<List<Destination>> addRecentStation(Destination station) async {
    final current = await loadRecentStations();
    final updated = [
      station,
      ...current.where(
        (existing) =>
            existing.name != station.name ||
            existing.latitude != station.latitude ||
            existing.longitude != station.longitude,
      ),
    ].take(_maxRecentStations).toList(growable: false);

    await saveRecentStations(updated);
    return updated;
  }
}
