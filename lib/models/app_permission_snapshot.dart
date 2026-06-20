import 'dart:io';

class AppPermissionSnapshot {
  const AppPermissionSnapshot({
    required this.locationWhenInUseGranted,
    required this.backgroundLocationGranted,
    required this.notificationsGranted,
    required this.locationServicesEnabled,
    required this.batteryOptimizationEnabled,
  });

  final bool locationWhenInUseGranted;
  final bool backgroundLocationGranted;
  final bool notificationsGranted;
  final bool locationServicesEnabled;
  /// `true` when Android battery optimization is still limiting the app.
  final bool batteryOptimizationEnabled;

  bool get allRequiredForMonitoring {
    if (!locationServicesEnabled || !locationWhenInUseGranted) {
      return false;
    }

    if (Platform.isAndroid) {
      return backgroundLocationGranted && notificationsGranted;
    }

    return true;
  }

  bool get batteryUnrestricted => !batteryOptimizationEnabled;

  List<String> get missingRequiredLabels {
    final missing = <String>[];
    if (!locationServicesEnabled) {
      missing.add('Phone GPS / location services turned on');
    }
    if (!locationWhenInUseGranted) {
      missing.add(
        Platform.isAndroid
            ? 'Location: Allow only while using the app (first step)'
            : 'Location: Allow While Using the App',
      );
    }
    if (Platform.isAndroid && !backgroundLocationGranted) {
      missing.add('Location: Allow all the time');
    }
    if (Platform.isAndroid && !notificationsGranted) {
      missing.add('Notifications: Allowed');
    }
    return missing;
  }
}
