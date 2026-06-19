import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/monitoring_state.dart';
import '../services/destination_storage_service.dart';

class MonitoringProvider extends ChangeNotifier {
  MonitoringProvider(this._destinationStorage);

  final DestinationStorageService _destinationStorage;

  MonitoringState _currentState = MonitoringState.idle;
  Destination? _selectedDestination;
  int _radiusMeters = 1000;

  MonitoringState get currentState => _currentState;
  Destination? get selectedDestination => _selectedDestination;
  int get radiusMeters => _radiusMeters;

  bool get isMonitoring => _currentState == MonitoringState.monitoring;

  Future<void> loadSavedDestination() async {
    final destination = await _destinationStorage.loadDestination();
    if (destination == null) {
      return;
    }

    _selectedDestination = destination;
    if (_currentState != MonitoringState.monitoring) {
      _currentState = MonitoringState.idle;
    }
    notifyListeners();
  }

  Future<void> setDestination(Destination destination) async {
    _selectedDestination = destination;
    if (_currentState != MonitoringState.monitoring) {
      _currentState = MonitoringState.idle;
    }

    await _destinationStorage.saveDestination(destination);
    notifyListeners();
  }

  Future<void> clearDestination() async {
    if (_selectedDestination == null) {
      return;
    }

    _selectedDestination = null;
    _currentState = MonitoringState.idle;

    await _destinationStorage.clearDestination();
    notifyListeners();
  }

  void setRadius(int meters) {
    if (meters <= 0 || meters == _radiusMeters) {
      return;
    }

    _radiusMeters = meters;
    notifyListeners();
  }

  void startMonitoring() {
    if (_selectedDestination == null) {
      return;
    }

    if (_currentState == MonitoringState.monitoring) {
      return;
    }

    _currentState = MonitoringState.monitoring;
    notifyListeners();
  }

  void stopMonitoring() {
    if (_currentState == MonitoringState.idle) {
      return;
    }

    _currentState = MonitoringState.idle;
    notifyListeners();
  }

  void markArrived() {
    if (_currentState != MonitoringState.monitoring) {
      return;
    }

    _currentState = MonitoringState.arrived;
    notifyListeners();
  }

  void resetToIdle() {
    if (_currentState == MonitoringState.idle) {
      return;
    }

    _currentState = MonitoringState.idle;
    notifyListeners();
  }
}
