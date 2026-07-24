import 'dart:io';

class AppPermissionSnapshot {
  const AppPermissionSnapshot({
    required this.locationWhenInUseGranted,
    required this.backgroundLocationGranted,
    required this.notificationsGranted,
    required this.activityRecognitionGranted,
    required this.locationServicesEnabled,
    required this.batteryOptimizationEnabled,
  });

  final bool locationWhenInUseGranted;
  final bool backgroundLocationGranted;
  final bool notificationsGranted;
  final bool activityRecognitionGranted;
  final bool locationServicesEnabled;
  /// `true` when Android battery optimization is still limiting the app.
  final bool batteryOptimizationEnabled;

  bool allRequiredForMonitoring({bool requireActivityRecognition = false}) {
    if (!locationServicesEnabled || !locationWhenInUseGranted) {
      return false;
    }

    if (Platform.isAndroid) {
      return backgroundLocationGranted &&
          notificationsGranted &&
          (!requireActivityRecognition || activityRecognitionGranted) &&
          batteryUnrestricted;
    }

    if (Platform.isIOS) {
      return backgroundLocationGranted && notificationsGranted;
    }

    return true;
  }

  bool get batteryUnrestricted => !batteryOptimizationEnabled;

  List<String> missingRequiredLabels({
    bool requireActivityRecognition = false,
  }) {
    final missing = <String>[];
    if (!locationServicesEnabled) {
      missing.add('Phone GPS / location services turned on');
    }
    if (!locationWhenInUseGranted) {
      missing.add(
        Platform.isAndroid
            ? 'Location — allow while using the app (first step)'
            : Platform.isIOS
                ? 'Location — Allow While Using the App (first step)'
                : 'Location — allow while using the app',
      );
    }
    if ((Platform.isAndroid || Platform.isIOS) && !backgroundLocationGranted) {
      missing.add(
        Platform.isIOS
            ? 'Location Always — keep watching while screen is locked'
            : 'Background location — keep watching while screen is off',
      );
    }
    if ((Platform.isAndroid || Platform.isIOS) && !notificationsGranted) {
      missing.add('Notifications — wake you with sound and vibration');
    }
    if (Platform.isAndroid &&
        requireActivityRecognition &&
        !activityRecognitionGranted) {
      missing.add('Physical activity — tell when you\'re on the train');
    }
    if (Platform.isAndroid && !batteryUnrestricted) {
      missing.add('Battery — so Android doesn\'t stop the trip');
    }
    return missing;
  }
}
