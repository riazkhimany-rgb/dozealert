import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/transit_line.dart';
import '../models/transit_station.dart';
import '../services/transit_data_service.dart';
import 'monitoring_provider.dart';
import 'transit_provider.dart';

class TransitLineProvider extends ChangeNotifier {
  TransitLineProvider(
    this._transitDataService,
    this._transitProvider,
    this._monitoringProvider,
  );

  final TransitDataService _transitDataService;
  final TransitProvider _transitProvider;
  final MonitoringProvider _monitoringProvider;

  TransitLine? _currentLine;
  TransitStation? _selectedDestinationStation;

  TransitLine? get currentLine => _currentLine;
  List<TransitStation> get currentStations => _currentLine?.stations ?? const [];
  TransitStation? get selectedDestinationStation => _selectedDestinationStation;

  Future<void> loadCurrentLine() async {
    final preferences = _transitProvider.preferences;
    final line = await _transitDataService.loadLine(
      country: preferences.country,
      transitSystem: preferences.transitSystem,
      lineName: preferences.defaultLine,
    );

    _currentLine = line;
    _selectedDestinationStation = null;
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
    await _transitProvider.recordRecentStation(destination);
    notifyListeners();
  }

  Future<void> selectRecentDestination(Destination destination) async {
    await _monitoringProvider.setDestination(destination);
    await _transitProvider.recordRecentStation(destination);

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
