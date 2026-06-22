import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

  Future<void> applyGoTransitDefaultsIfUnset() async {
    if (await _preferencesService.hasConfiguredTransitPreferences()) {
      return;
    }

    _preferences = const TransitPreferences(
      country: 'Canada',
      region: 'Ontario',
      transitSystem: 'GO Transit',
      defaultLine: 'Lakeshore West',
    );
    await savePreferences();
    notifyListeners();
  }

  Future<void> applyDeviceLocaleDefaultsIfUnset() async {
    if (await _preferencesService.hasConfiguredTransitPreferences()) {
      return;
    }

    final locale = SchedulerBinding.instance.platformDispatcher.locale;
    _preferences = TransitCatalog.preferencesForLocale(locale);
    await savePreferences();
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

    final region = TransitCatalog.defaultRegionForCountry(country);
    final transitSystem = TransitCatalog.defaultAgencyForRegion(country, region);
    final defaultLine = TransitCatalog.defaultLineForSystem(transitSystem);

    _preferences = _preferences.copyWith(
      country: country,
      region: region,
      transitSystem: transitSystem,
      defaultLine: defaultLine,
    );
    await savePreferences();
    notifyListeners();
  }

  Future<void> setRegion(String region) async {
    if (!TransitCatalog.isValidRegionForCountry(_preferences.country, region) ||
        region == _preferences.region) {
      return;
    }

    final transitSystem = TransitCatalog.defaultAgencyForRegion(
      _preferences.country,
      region,
    );
    final defaultLine = TransitCatalog.defaultLineForSystem(transitSystem);

    _preferences = _preferences.copyWith(
      region: region,
      transitSystem: transitSystem,
      defaultLine: defaultLine,
    );
    await savePreferences();
    notifyListeners();
  }

  Future<void> setTransitSystem(String transitSystem) async {
    if (!TransitCatalog.isValidAgencyForRegion(
          _preferences.country,
          _preferences.region,
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
    if (defaultLine.isEmpty || defaultLine == _preferences.defaultLine) {
      return;
    }

    _preferences = _preferences.copyWith(defaultLine: defaultLine);
    await savePreferences();
    notifyListeners();
  }

  Future<void> applyTransitSelection({
    required String country,
    required String region,
    required String transitSystem,
    required String defaultLine,
  }) async {
    final normalized = TransitCatalog.normalize(
      TransitPreferences(
        country: country,
        region: region,
        transitSystem: transitSystem,
        defaultLine: defaultLine,
      ),
    );

    if (_preferences == normalized) {
      return;
    }

    _preferences = normalized;
    await savePreferences();
    notifyListeners();
  }

  Future<void> recordRecentStation(Destination station) async {
    _recentStations = await _preferencesService.addRecentStation(station);
    notifyListeners();
  }
}
