import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/transit_line.dart';
import '../models/transit_preferences.dart';
import '../models/transit_station.dart';
import '../services/transit_data_service.dart';
import 'monitoring_provider.dart';
import 'transit_provider.dart';
import '../utils/app_log.dart';

class TransitLineProvider extends ChangeNotifier {
  TransitLineProvider(
    this._transitDataService,
    this._transitProvider,
    this._monitoringProvider,
  ) {
    _lastPreferencesKey = _preferencesKey(_transitProvider.preferences);
    _transitProvider.addListener(_handlePreferencesChanged);
  }

  final TransitDataService _transitDataService;
  final TransitProvider _transitProvider;
  final MonitoringProvider _monitoringProvider;

  TransitLine? _currentLine;
  List<TransitStation> _currentStations = const [];
  TransitStation? _selectedDestinationStation;
  String? _loadedAssetPath;
  String? _loadError;
  bool _isLoading = false;
  String _lastPreferencesKey = '';

  TransitLine? get currentLine => _currentLine;
  List<TransitStation> get currentStations => _currentStations;
  TransitStation? get selectedDestinationStation => _selectedDestinationStation;
  String? get loadedAssetPath => _loadedAssetPath;
  String? get loadError => _loadError;
  int get stationCount => _currentStations.length;
  bool get isLoading => _isLoading;

  String get currentCountry => _transitProvider.preferences.country;
  String get currentTransitSystem => _transitProvider.preferences.transitSystem;
  String get currentLineName => _transitProvider.preferences.defaultLine;

  List<TransitStation> filterStations(String query) {
    return _transitDataService.filterStations(_currentStations, query);
  }

  @override
  void dispose() {
    _transitProvider.removeListener(_handlePreferencesChanged);
    super.dispose();
  }

  void _handlePreferencesChanged() {
    final nextKey = _preferencesKey(_transitProvider.preferences);
    if (nextKey == _lastPreferencesKey) {
      return;
    }

    _lastPreferencesKey = nextKey;
    loadCurrentLine();
  }

  String _preferencesKey(TransitPreferences preferences) {
    return '${preferences.country}|${preferences.transitSystem}|${preferences.defaultLine}';
  }

  Future<void> loadCurrentLine() async {
    final preferences = _transitProvider.preferences;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    final result = await _transitDataService.loadLine(
      country: preferences.country,
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );

    _loadedAssetPath = result.assetPath;
    _currentLine = result.line;
    _currentStations = result.line?.stations ?? const [];
    _loadError = result.error;
    _selectedDestinationStation = null;
    _isLoading = false;

    if (result.isSuccess) {
      AppLog.d(
        'TransitLineProvider: ${result.fromCache ? 'cache hit' : 'loaded'} '
        '${result.assetPath} (${result.stationCount} stations)',
      );
    } else {
      AppLog.d(
        'TransitLineProvider: failed to load ${result.assetPath}: ${result.error}',
      );
    }

    notifyListeners();
  }

  Future<void> setDestinationStation(TransitStation station) async {
    _selectedDestinationStation = station;

    final destination = Destination(
      name: station.name,
      latitude: station.latitude,
      longitude: station.longitude,
    );

    await _monitoringProvider.setDestination(destination);
    notifyListeners();
  }

  Future<void> selectRecentDestination(Destination destination) async {
    await _monitoringProvider.setDestination(destination);

    final line = _currentLine;
    _selectedDestinationStation = line == null
        ? null
        : _transitDataService.getStationByName(line, destination.name);
    notifyListeners();
  }

  void clearSelectedDestinationStation() {
    if (_selectedDestinationStation == null) {
      return;
    }

    _selectedDestinationStation = null;
    notifyListeners();
  }
}
