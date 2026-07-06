import 'package:flutter/foundation.dart';

/// Phone-side Wear OS status for the DozeAlert watch app specifically.
///
/// [appInstalled] is true only when the DozeAlert watch app is present on a
/// paired watch (even if that watch is momentarily offline). [watchConnected]
/// is true when that watch is currently reachable.
class WearStatusProvider extends ChangeNotifier {
  bool _appInstalled = false;
  bool _watchConnected = false;
  bool _checked = false;

  bool get appInstalled => _appInstalled;
  bool get watchConnected => _watchConnected;
  bool get hasChecked => _checked;

  void setWearStatus({required bool appInstalled, required bool connected}) {
    final effectiveConnected = appInstalled && connected;
    final changed = _appInstalled != appInstalled ||
        _watchConnected != effectiveConnected ||
        !_checked;
    _checked = true;
    _appInstalled = appInstalled;
    _watchConnected = effectiveConnected;
    if (changed) {
      notifyListeners();
    }
  }
}
