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

  static const savedAndRecentTitle = 'Saved & recent';

  static const wakeAlertTitle = 'Wake alert';

  static const alertDistanceLabel = 'Alert distance';

  static const setupBeforeStartTitle = 'Before you start';

  static const clear = 'Clear';

  static const changeWakeStops = 'Change alert stops';

  static const quickPicksTitle = 'Quick picks';

  static const noQuickPicksStopsYet =
      'No recent or saved stops yet. Pick a stop to start building this list.';

  static const noQuickPicksDestinationsYet =
      'No recent or saved destinations yet. Set a destination to start building this list.';


  static const startTrip = 'Start';

  static const startingTrip = 'Starting…';

  static const stopTrip = 'Stop trip';

  static const stoppingTrip = 'Stopping…';

  static const changeWakeDistance = 'Change alert distance';

  static const watchingTripLine1 = 'Watching';
  static const watchingTripLine2 = 'your trip';

  static const watchConnected = 'Watch connected';
  static const watchNotConnected = 'Watch disconnected';

  static const readyWhenYouAre = 'Ready when you are';

  /// Shown when destination is set but monitoring has not started (avoids repeating "ready").
  static const startWhenOnBoard = 'Tap Start when you\'re on board';

  static const yourStop = 'Your stop';

  static const yourDestination = 'Your destination';

  static const lockPhoneHint = 'You can lock your phone now.';

  static const emptyHeadline = 'Where are you getting off?';

  static const emptySubtitle = 'Pick your stop on your route.';

  static String emptySubtitleForWake(TransitModeWakeSetting wakeSetting) {
    return '$emptySubtitle ${defaultWakeSummary(wakeSetting)}.';
  }

  static const emptyHeadlineDistance = 'Where are you going?';

  static const emptySubtitleDistance =
      'Search on the map or drop a pin. We wake you within your alert distance.';

  static const myTripsEmptyMessage =
      'Save stops you use often and start a trip with one tap.';

  static const myTripsEmptyMessageDistance =
      'Save destinations you use often and start a trip with one tap.';

  static const savedStopsTitle = 'Saved stops';
  static const savedDestinationsTitle = 'Saved destinations';
  static const recentStopsTitle = 'Recent stops';
  static const recentDestinationsTitle = 'Recent destinations';

  static const savedStopsSubtitle = "Start a trip to a stop you've saved.";
  static const savedDestinationsSubtitle =
      "Start a trip to a destination you've saved.";
  static const recentStopsSubtitle =
      "Start a trip to a stop you've used recently.";
  static const recentDestinationsSubtitle =
      "Start a trip to a destination you've used recently.";

  static const noSavedStopsYet = 'No saved stops yet.';
  static const noSavedDestinationsYet = 'No saved destinations yet.';
  static const noRecentStopsYet = 'No recent stops yet.';
  static const noRecentDestinationsYet = 'No recent destinations yet.';

  static const useAndStartTrip = 'Use and start trip';

  static const pastTripsTitle = 'Past trips';
  static const pastTripsSettingsSubtitle =
      'Completed trips, stats, and missed stops';
  static const pastTripsIntro =
      'Completed trips and alerts when you missed your stop.';
  static const pastTripsCompletedSection = 'Completed trips';
  static const pastTripsCompletedSubtitle =
      'Trips where you reached your destination.';
  static const pastTripsMissedSection = 'Missed trips';
  static const pastTripsMissedSubtitle =
      'Trips where the wake alert was not dismissed in time.';
  static const pastTripsStatsSubtitle =
      'Totals and streaks for recent trip activity.';
  static const pastTripsCompletedEmpty = 'Completed trips will appear here.';
  static const pastTripsMissedEmpty = 'No missed trips recorded.';

  static const onboardingSkipSnackBar =
      'Finish setup anytime in Settings → Permissions.';

  static const onboardingModeTitle = 'How do you usually travel?';
  static const onboardingModeBody =
      'Choose one to personalize setup. You can change this later in '
      'Settings → Transit → Transit Mode.';
  static const onboardingModeTransitTitle = 'Transit';
  static const onboardingModeTransitSubtitle =
      'Bus, train, or subway — wake by stops on your route.';
  static const onboardingModeDistanceTitle = 'Taxi, rideshare, or map';
  static const onboardingModeDistanceSubtitle =
      'Wake by distance to a pin or place on the map.';

  static const findingLocation = 'Finding your location…';

  /// Shared phrasing for stop counts across Home, notifications, and alarms.
  static String stopsRemainingLabel(
    int stopsRemaining, {
    StopsRemainingStyle style = StopsRemainingStyle.progress,
  }) {
    if (stopsRemaining <= 0) {
      return switch (style) {
        StopsRemainingStyle.progress => 'At destination stop',
        StopsRemainingStyle.notification => 'At your stop',
        StopsRemainingStyle.alarm => 'Time to get off',
      };
    }
    if (stopsRemaining == 1) {
      return switch (style) {
        StopsRemainingStyle.progress => '1 stop to go',
        StopsRemainingStyle.notification => '1 stop remaining',
        StopsRemainingStyle.alarm => '1 more stop to go',
      };
    }
    return switch (style) {
      StopsRemainingStyle.progress => '$stopsRemaining stops to go',
      StopsRemainingStyle.notification => '$stopsRemaining stops remaining',
      StopsRemainingStyle.alarm => '$stopsRemaining more stops to go',
    };
  }

  /// Avoid claiming physical arrival when stop bookkeeping has advanced to the
  /// destination but route geometry still shows meaningful travel remaining.
  static String transitProgressLabel({
    required int stopsRemaining,
    double? alongRouteRemainingMeters,
  }) {
    if (stopsRemaining <= 0 &&
        alongRouteRemainingMeters != null &&
        alongRouteRemainingMeters > 250) {
      return 'Approaching destination';
    }
    return stopsRemainingLabel(
      stopsRemaining,
      style: StopsRemainingStyle.progress,
    );
  }

  static String stayOnBoardForStopsRemaining(int stopsRemaining) {
    return stayOnBoard;
  }

  static const gpsSignalWeakBase =
      'GPS signal weak — using last known position';

  static String gpsSignalWeakMessage({String? lineName}) {
    if (lineName != null && lineName.isNotEmpty) {
      return '$gpsSignalWeakBase on $lineName';
    }
    return gpsSignalWeakBase;
  }

  static const staleDistanceSubtitle = 'Last known distance';

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
      TransitModeWakeSetting.twoStopsBefore =>
        'Wake 2 stops before $destination',
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
      return gpsSignalWeakMessage();
    }
    return lockPhoneHint;
  }

  static const onboardingIntroTitle = 'Wake up before you arrive';

  static const onboardingIntroBody =
      'DozeAlert tracks your ride and sounds an alarm when you are '
      'approaching your destination — on transit, in a taxi or rideshare, '
      'or any trip where GPS works.\n\n'
      'Next, choose how you usually travel. Then we\'ll ask for a few phone '
      'permissions so we can watch your trip while you sleep.\n\n'
      'After that, pick your stop or destination on Home and tap Start.';

  static const permissionsHeadline = 'Allow what DozeAlert needs';

  static const permissionsIntroAndroid =
      'So we can track your ride and wake you before your stop. '
      'Tap the button below — we\'ll walk you through each permission '
      'one at a time.';

  static const permissionsIntroIos =
      'So we can track your ride and wake you before your stop. '
      'Tap the button below — we\'ll walk you through location '
      '(While Using, then Always) and notifications.';

  static const enableAndContinue = 'Enable & continue';

  static const resumePermissionSetup = 'Resume setup';

  static const permissionsReadyHint = 'All set — tap Get started below.';

  static const readyToSleepTitle = 'Ready to sleep?';

  static const readyToSleepNotYet = 'Not yet';

  static const startMyTrip = 'Start my trip';

  static String wakeSettingsTourBody(TransitModeWakeSetting wakeSetting) {
    return 'Choose when to wake up — ${defaultWakeSummary(wakeSetting).toLowerCase()} '
        'is the default. You can change this anytime before or during a trip.';
  }

  static String readyToSleepBody({
    required TransitModeWakeSetting wakeSetting,
    String? destinationName,
    String? wakeAtStopName,
  }) {
    final wakeLine = destinationName != null
        ? wakeTargetLabel(
            wakeSetting: wakeSetting,
            destinationName: destinationName,
            wakeAtStopName: wakeAtStopName,
          )
        : defaultWakeSummary(wakeSetting);
    return '$wakeLine.\n\n'
        'Keep your phone charged and volume on, then relax.';
  }

  static const almostReadyTitle = 'Almost ready';

  static const almostReadySubtitle =
      'Complete these steps before you fall asleep:';

  static const getReadyHeadline = 'GET READY';

  static const timeToGetOffHeadline = 'TIME TO GET OFF';

  static String destinationIsYourStop(String destinationName) =>
      '$destinationName is your stop';

  static const isYourStopLine = 'is your stop';

  static const stayOnBoard = 'Stay on board';

  static const dismissAlarm = 'Dismiss';

  static const alarmContinuesUntilDismiss = 'Alarm continues until you dismiss';

  static const youAreAtPrefix = 'You are at ';

  static const confirmingRoute = 'Confirming your route…';

  static const routeProgressBeforeStart =
      'Start your trip to see stop-by-stop progress.';

  static const permissionReasonLocation = 'Know which stop you\'re passing';

  static const permissionReasonBackground =
      'Keep watching while your screen is off';

  static const permissionReasonNotifications =
      'Wake you with sound and vibration';

  static const permissionReasonActivity =
      'Tell when you\'re on the train vs at the platform';

  static const permissionReasonBattery = 'So Android doesn\'t stop the trip';

  static const permissionDialogLocationBody =
      'Android asks for location in two steps. This is step 1 — '
      'so DozeAlert can see your position while the app is open.';

  static const permissionDialogLocationBodyIos =
      'iOS asks for location in two steps. This is step 1 — '
      'so DozeAlert can see your position while the app is open.';

  static const permissionDialogLocationHighlight = 'Tap "While using the app"';

  static const permissionDialogLocationHighlightIos =
      'Tap "Allow While Using the App"';

  static const permissionDialogBackgroundBody =
      'DozeAlert needs background location so your trip keeps running '
      'when you lock your phone or switch apps.\n\n'
      'The next screen may be an Android dialog or app settings.';

  static const permissionDialogBackgroundBodyIos =
      'Apple requires Always location in Settings (apps cannot turn '
      'this on for you).\n\n'
      'Tap Continue — we open Settings. On newer iOS, use Search: type '
      'DozeAlert, open it, then Location → Always.';

  static const permissionDialogBackgroundHighlight =
      'Choose "Allow all the time"';

  static const permissionDialogBackgroundHighlightIos =
      '1. Search "DozeAlert"\n2. Tap Location\n3. Tap Always';

  static const iosAlwaysSettingsTitle = 'Turn on Always location';

  static const iosAlwaysSettingsBody =
      'Apple does not let apps enable Always location by themselves.\n\n'
      'Tap Open Settings. Then use Search (fastest on newer iOS):';

  static const iosAlwaysSettingsStep1 = 'Search for DozeAlert and open it';

  static const iosAlwaysSettingsStep2 = 'Tap Location, then Always';

  static const iosAlwaysSettingsOpenButton = 'Open Settings';

  static const iosAlwaysRecoveryBody =
      'While Using is on, but Always is still off — needed so we can '
      'watch your trip while you sleep.\n\n'
      'Tap Open Settings, search DozeAlert, then Location → Always.';

  static const permissionDialogNotificationsBody =
      'DozeAlert shows a small ongoing notification while watching '
      'your trip, and uses alerts to wake you before your stop.';

  static const permissionDialogNotificationsBodyIos =
      'DozeAlert uses notifications to wake you before your stop, '
      'even when the app is in the background.';

  static const permissionDialogNotificationsHighlight = 'Tap "Allow"';

  static const permissionDialogActivityBody =
      'Physical activity helps DozeAlert tell when you are riding '
      'versus waiting at a station — so wake timing stays accurate.';

  static const permissionDialogActivityHighlight = 'Tap "Allow"';

  static const permissionDialogBatteryBody =
      'Some phones limit background apps. Allowing battery exemption '
      'helps your alarm stay reliable while you sleep.';

  static const permissionDialogBatteryHighlight =
      'Tap "Allow" or "Unrestricted"';

  static const activityRecognitionSettingTitle = 'Physical activity detection';

  static const activityRecognitionEnabledSubtitle =
      'Helps tell riding from waiting at a platform — can improve wake timing '
      'on transit. Uses Android physical activity permission.';

  static const activityRecognitionDisabledSubtitle =
      'Off — wake uses GPS only. Route lock may take longer; less accurate '
      'if you are still at the station.';

  static const activityRecognitionPermissionDenied =
      'Physical activity permission is required when this is turned on.';

  static const tripCouldNotStartTitle = 'Trip could not start';

  static const tripCouldNotStartBody =
      'DozeAlert could not start watching your trip. Check location, '
      'notification, and battery settings, then try again.';

  static const selectDestinationBeforeTrip =
      'Pick your stop before starting a trip.';

  static const turnOnGpsToStartTrip = 'Turn on GPS to start your trip.';

  static const tripMayStopWhenScreenOff =
      'Your trip may stop when the screen is off.';

  static const backgroundTripActive = 'Background trip active';

  static const foregroundServiceRunning = 'Trip service is running.';

  static const startTripFromHomeHint = 'Start your trip from Home to enable.';

  static const notificationChannelName = 'Active trips';

  static const notificationChannelDescription =
      'Shown while DozeAlert watches your trip in the background.';

  static const notificationWatchingTrip = 'Watching your trip…';

  static const notificationTripPausedGpsOff = 'Trip paused — GPS is off.';

  static const notificationTripPausedNoLocation =
      'Trip paused — location unavailable.';

  static String notificationTripStatus({
    required String destinationName,
    required String statusDetail,
  }) {
    return '$notificationWatchingTrip\n$destinationName · $statusDetail';
  }

  static String notificationKmRemaining(double distanceKm) {
    return '${distanceKm.toStringAsFixed(1)} km remaining';
  }

  static String notificationStopsRemaining(int stopsRemaining) {
    return stopsRemainingLabel(
      stopsRemaining,
      style: StopsRemainingStyle.notification,
    );
  }
}

enum StopsRemainingStyle { progress, notification, alarm }
