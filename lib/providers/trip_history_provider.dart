import 'package:flutter/material.dart';

import '../models/trip_history_entry.dart';
import '../services/trip_history_service.dart';

class TripHistoryProvider extends ChangeNotifier {
  TripHistoryProvider(this._tripHistoryService);

  final TripHistoryService _tripHistoryService;

  List<TripHistoryEntry> _entries = const [];

  List<TripHistoryEntry> get entries => _entries;

  List<TripHistoryEntry> get completedTrips {
    return _entries
        .where((entry) => !entry.missedTrip && entry.tripEnd != null)
        .toList(growable: false);
  }

  List<TripHistoryEntry> get missedTrips {
    return _entries
        .where((entry) => entry.missedTrip)
        .toList(growable: false);
  }

  Future<void> load() async {
    _entries = await _tripHistoryService.loadHistory();
    notifyListeners();
  }

  Future<void> refresh() async {
    await load();
  }
}
