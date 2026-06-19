import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/monitoring_state.dart';

class MonitoringProvider extends ChangeNotifier {
  MonitoringState _currentState = MonitoringState.idle;
  Destination? _selectedDestination;
  int _radiusMeters = 1000;

  MonitoringState get currentState => _currentState;
  Destination? get selectedDestination => _selectedDestination;
  int get radiusMeters => _radiusMeters;

  bool get isMonitoring => _currentState == MonitoringState.monitoring;

  void setDestination(Destination destination) {
    _selectedDestination = destination;
    if (_currentState != MonitoringState.monitoring) {
      _currentState = MonitoringState.idle;
    }
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
}
