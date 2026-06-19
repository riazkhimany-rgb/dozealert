import 'package:flutter/material.dart';

import '../data/transit_catalog.dart';
import '../models/destination.dart';
import '../models/transit_preferences.dart';
import '../services/preferences_service.dart';

class TransitProvider extends ChangeNotifier {
  TransitProvider(this._preferencesService);

  final PreferencesService _preferencesService;

  TransitPreferences _preferences = TransitPreferences.defaults;
  List<Destination> _recentStations = const [];

  TransitPreferences get preferences => _preferences;
  List<Destination> get recentStations => _recentStations;

  Future<void> loadPreferences() async {
    _preferences = await _preferencesService.loadTransitPreferences();
    _recentStations = await _preferencesService.loadRecentStations();
    notifyListeners();
  }

  Future<void> savePreferences() async {
    await _preferencesService.saveTransitPreferences(_preferences);
  }

  Future<void> setCountry(String country) async {
    if (!TransitCatalog.isValidCountry(country) ||
        country == _preferences.country) {
      return;
    }

    final transitSystem = TransitCatalog.defaultSystemForCountry(country);
    final defaultLine = TransitCatalog.defaultLineForSystem(transitSystem);

    _preferences = _preferences.copyWith(
      country: country,
      transitSystem: transitSystem,
      defaultLine: defaultLine,
    );
    await savePreferences();
    notifyListeners();
  }

  Future<void> setTransitSystem(String transitSystem) async {
    if (!TransitCatalog.isValidSystemForCountry(
          _preferences.country,
          transitSystem,
        ) ||
        transitSystem == _preferences.transitSystem) {
      return;
    }

    final defaultLine = TransitCatalog.defaultLineForSystem(transitSystem);

    _preferences = _preferences.copyWith(
      transitSystem: transitSystem,
      defaultLine: defaultLine,
    );
    await savePreferences();
    notifyListeners();
  }

  Future<void> setDefaultLine(String defaultLine) async {
    if (!TransitCatalog.isValidLineForSystem(
          _preferences.transitSystem,
          defaultLine,
        ) ||
        defaultLine == _preferences.defaultLine) {
      return;
    }

    _preferences = _preferences.copyWith(defaultLine: defaultLine);
    await savePreferences();
    notifyListeners();
  }

  Future<void> recordRecentStation(Destination station) async {
    _recentStations = await _preferencesService.addRecentStation(station);
    notifyListeners();
  }
}
