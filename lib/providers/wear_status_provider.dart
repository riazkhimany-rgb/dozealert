import 'package:flutter/foundation.dart';

/// Phone-side Wear OS pairing / connection status.
class WearStatusProvider extends ChangeNotifier {
  bool _watchConnected = false;
  bool _checked = false;

  bool get watchConnected => _watchConnected;
  bool get hasChecked => _checked;

  void setWatchConnected(bool connected) {
    _checked = true;
    if (_watchConnected == connected) {
      return;
    }
    _watchConnected = connected;
    notifyListeners();
  }
}
