import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the interactive Home screen coach-mark tour.
class AppTourService extends ChangeNotifier {
  static const _homeTourCompleteKey = 'home_tour_complete';
  static const _homeTourPendingKey = 'home_tour_pending';

  bool _replayRequested = false;

  bool get replayRequested => _replayRequested;

  Future<bool> shouldShowHomeTour() async {
    if (_replayRequested) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_homeTourPendingKey) ?? false;
    final complete = prefs.getBool(_homeTourCompleteKey) ?? false;
    return pending && !complete;
  }

  Future<void> markHomeTourPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeTourPendingKey, true);
  }

  Future<void> markHomeTourComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeTourCompleteKey, true);
    await prefs.setBool(_homeTourPendingKey, false);
    _replayRequested = false;
    notifyListeners();
  }

  void requestReplay() {
    _replayRequested = true;
    notifyListeners();
  }

  void clearReplayRequest() {
    if (!_replayRequested) {
      return;
    }
    _replayRequested = false;
    notifyListeners();
  }

  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_homeTourCompleteKey);
    await prefs.remove(_homeTourPendingKey);
    _replayRequested = false;
    notifyListeners();
  }
}
