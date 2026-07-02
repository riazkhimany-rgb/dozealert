import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination.dart';

class DestinationStorageService {
  static const _nameKey = 'selected_destination_name';
  static const _latitudeKey = 'selected_destination_latitude';
  static const _longitudeKey = 'selected_destination_longitude';
  static const _stationKeyKey = 'selected_destination_station_key';

  Future<void> saveDestination(Destination destination) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_nameKey, destination.name);
    await prefs.setDouble(_latitudeKey, destination.latitude);
    await prefs.setDouble(_longitudeKey, destination.longitude);
    if (destination.stationKey != null) {
      await prefs.setString(_stationKeyKey, destination.stationKey!);
    } else {
      await prefs.remove(_stationKeyKey);
    }
  }

  Future<Destination?> loadDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);

    if (name == null || latitude == null || longitude == null) {
      return null;
    }

    return Destination(
      name: name,
      latitude: latitude,
      longitude: longitude,
      stationKey: prefs.getString(_stationKeyKey),
    );
  }

  Future<void> clearDestination() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_nameKey);
    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
    await prefs.remove(_stationKeyKey);
  }
}
