import 'dart:async';

import 'package:flutter/material.dart';

import '../models/agency_detection_result.dart';
import '../models/destination.dart';
import '../models/transit_agency.dart';
import '../models/transit_stop.dart';
import '../services/gtfs_service.dart';
import 'monitoring_provider.dart';
import 'train_mode_provider.dart';
import 'transit_provider.dart';

class GtfsProvider extends ChangeNotifier {
  GtfsProvider(
    this._gtfsService,
    this._transitProvider,
    this._monitoringProvider,
    this._trainModeProvider,
  ) {
    _monitoringProvider.addListener(_handleDestinationChanged);
  }

  final GtfsService _gtfsService;
  final TransitProvider _transitProvider;
  final MonitoringProvider _monitoringProvider;
  final TrainModeProvider _trainModeProvider;

  bool _initialized = false;
  AgencyDetectionResult? _lastDetection;

  bool get isInitialized => _initialized;
  AgencyDetectionResult? get lastDetection => _lastDetection;
  List<TransitAgency> get agencies => _gtfsService.agencies;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _gtfsService.initializeFromFallbackData();
    _initialized = true;
    notifyListeners();

    final destination = _monitoringProvider.selectedDestination;
    if (destination != null) {
      await detectAndApplyForDestination(destination);
    }
  }

  List<TransitStop> searchStops(String query) {
    if (!_initialized) {
      return const [];
    }
    return _gtfsService.searchStops(query);
  }

  AgencyDetectionResult? detectAgencyFromDestination(String destinationName) {
    return _gtfsService.detectAgencyFromDestination(destinationName);
  }

  Future<void> selectStop(TransitStop stop) async {
    _trainModeProvider.setActiveRouteId(stop.routeId);

    final destination = Destination(
      name: stop.stopName,
      latitude: stop.latitude,
      longitude: stop.longitude,
    );

    await _monitoringProvider.setDestination(destination);
    await _transitProvider.recordRecentStation(destination);
    await detectAndApplyForDestination(destination);
    notifyListeners();
  }

  Future<void> detectAndApplyForDestination(Destination destination) async {
    if (!_initialized) {
      return;
    }

    final detection = _gtfsService.detectAgencyFromDestination(destination.name);
    _lastDetection = detection;
    if (detection == null) {
      notifyListeners();
      return;
    }

    final route = detection.route;
    if (route != null) {
      _trainModeProvider.setActiveRouteId(route.routeId);
      await _transitProvider.applyTransitSelection(
        country: route.country,
        transitSystem: route.transitSystem,
        defaultLine: route.lineName,
      );
    }

    notifyListeners();
  }

  void _handleDestinationChanged() {
    final destination = _monitoringProvider.selectedDestination;
    if (destination == null) {
      _lastDetection = null;
      notifyListeners();
      return;
    }

    unawaited(detectAndApplyForDestination(destination));
  }

  @override
  void dispose() {
    _monitoringProvider.removeListener(_handleDestinationChanged);
    super.dispose();
  }
}
