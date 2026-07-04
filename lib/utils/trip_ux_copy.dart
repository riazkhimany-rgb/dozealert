import '../models/transit_mode_wake_setting.dart';
import '../utils/gtfs_stop_name_utils.dart';

/// Plain-language copy for the simplified trip-first Home experience.
abstract final class TripUxCopy {
  static const myTripsTab = 'My Trips';

  static const pickYourStop = 'Pick your stop';

  static const pickDestination = 'Pick destination';

  static const setDestination = 'Set destination';

  static const saveToMyTrips = 'Save to My Trips';

  static const changeStop = 'Change stop';

  static const changeDestination = 'Change destination';

  static const changeLine = 'Change line';

  static const selectFromMyTrips = 'Select from My Trips';

  static const clearStop = 'Clear stop';

  static const clearDestination = 'Clear destination';

  static const changeWakeStops = 'Change wake stops';

  static const startTrip = 'Start';

  static const startingTrip = 'Starting…';

  static const stopTrip = 'Stop trip';

  static const stoppingTrip = 'Stopping…';

  static const changeWakeDistance = 'Change wake distance';

  static const watchingTripLine1 = 'Watching';
  static const watchingTripLine2 = 'your trip';

  static const readyWhenYouAre = 'Ready when you are';

  static const yourStop = 'Your stop';

  static const yourDestination = 'Your destination';

  static const lockPhoneHint = 'You can lock your phone now.';

  static const emptyHeadline = 'Where are you getting off?';

  static const emptySubtitle =
      'Pick your stop on your route. We wake you one stop before by default.';

  static const emptyHeadlineDistance = 'Where are you going?';

  static const emptySubtitleDistance =
      'Search on the map or drop a pin. We wake you within your alert distance.';

  static const myTripsEmptyMessage =
      'Save stops you use often and start a trip with one tap.';

  static const myTripsEmptyMessageDistance =
      'Save destinations you use often and start a trip with one tap.';

  static const moreOptions = 'More options';

  static const pickRoute = 'Pick your route';

  static const findingLocation = 'Finding your location…';

  static String defaultWakeSummary(TransitModeWakeSetting wakeSetting) {
    return switch (wakeSetting) {
      TransitModeWakeSetting.atDestination => 'Wake at your stop',
      TransitModeWakeSetting.oneStopBefore => 'Wake 1 stop before your stop',
      TransitModeWakeSetting.twoStopsBefore => 'Wake 2 stops before your stop',
    };
  }

  static String wakeTargetLabel({
    required TransitModeWakeSetting wakeSetting,
    required String destinationName,
    String? wakeAtStopName,
  }) {
    final destination = GtfsStopNameUtils.stationDisplayName(destinationName);

    if (wakeSetting == TransitModeWakeSetting.atDestination) {
      return 'Wake at $destination';
    }

    if (wakeAtStopName != null && wakeAtStopName.isNotEmpty) {
      return 'Wake at ${GtfsStopNameUtils.stationDisplayName(wakeAtStopName)}';
    }

    return switch (wakeSetting) {
      TransitModeWakeSetting.oneStopBefore => 'Wake 1 stop before $destination',
      TransitModeWakeSetting.twoStopsBefore => 'Wake 2 stops before $destination',
      TransitModeWakeSetting.atDestination => 'Wake at $destination',
    };
  }

  static String gpsStatusLabel({
    required bool establishingGps,
    required bool gpsPrewarming,
    required bool gpsSignalLost,
  }) {
    if (establishingGps || gpsPrewarming) {
      return findingLocation;
    }
    if (gpsSignalLost) {
      return 'GPS signal weak — using last known position';
    }
    return lockPhoneHint;
  }

  static const onboardingIntroTitle = 'Wake up before your stop';

  static const onboardingIntroBody =
      'DozeAlert tracks your ride and sounds an alarm when you are '
      'approaching your destination.\n\n'
      'First, choose the transit you ride. Then we\'ll ask for a few '
      'phone permissions so we can watch your trip while you sleep.\n\n'
      'After that, pick your stop on Home and tap Start.';

  static const permissionsHeadline = 'Allow what DozeAlert needs';

  static const permissionsIntroAndroid =
      'So we can track your ride and wake you before your stop. '
      'Tap the button below — we\'ll walk you through each permission '
      'one at a time.';

  static const permissionsIntroIos =
      'So we can track your ride and wake you before your stop. '
      'Tap the button below to grant location access.';

  static const enableAndContinue = 'Enable & continue';

  static const resumePermissionSetup = 'Resume setup';

  static const permissionsReadyHint =
      'All set — tap Get started below.';

  static const readyToSleepTitle = 'Ready to sleep?';

  static const readyToSleepNotYet = 'Not yet';

  static const startMyTrip = 'Start my trip';

  static String readyToSleepBody({required String destinationName}) =>
      'We\'ll wake you one stop before $destinationName.\n\n'
      'Keep your phone charged and volume on, then relax.';

  static const readyToSleepBodyDefault =
      'We wake you one stop before your stop by default.\n\n'
      'Keep your phone charged and volume on, then relax.';

  static const almostReadyTitle = 'Almost ready';

  static const almostReadySubtitle =
      'Complete these steps before you fall asleep:';

  static const getReadyHeadline = 'GET READY';

  static const timeToGetOffHeadline = 'TIME TO GET OFF';

  static String destinationIsYourStop(String destinationName) =>
      '$destinationName is your stop';

  static const stayOnBoardOneMoreStop = 'Stay on board — one more stop';

  static const stayOnBoardTwoMoreStops = 'Stay on board — two more stops';

  static const dismissAlarm = 'Dismiss';

  static const alarmContinuesUntilDismiss =
      'Alarm continues until you dismiss';

  static const youAreAtPrefix = 'You are at ';

  static const confirmingRoute = 'Confirming your route…';

  static const permissionReasonLocation = 'Know which stop you\'re passing';

  static const permissionReasonBackground =
      'Keep watching while your screen is off';

  static const permissionReasonNotifications =
      'Wake you with sound and vibration';

  static const permissionReasonActivity =
      'Tell when you\'re on the train vs at the platform';

  static const permissionReasonBattery = 'So Android doesn\'t stop the trip';
}
