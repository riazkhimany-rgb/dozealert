import '../models/transit_mode_wake_setting.dart';
import '../utils/gtfs_stop_name_utils.dart';

/// Plain-language copy for the simplified trip-first Home experience.
abstract final class TripUxCopy {
  static const myTripsTab = 'My Trips';

  static const pickYourStop = 'Pick your stop';

  static const changeStop = 'Change stop';

  static const changeLine = 'Change line';

  static const clearStop = 'Clear stop';

  static const startTrip = 'Start';

  static const stopTrip = 'Stop trip';

  static const watchingTrip = 'Watching your trip';

  static const readyWhenYouAre = 'Ready when you are';

  static const yourStop = 'Your stop';

  static const lockPhoneHint = 'You can lock your phone now.';

  static const emptyHeadline = 'Where are you getting off?';

  static const emptySubtitle =
      'Pick your stop on your route. We wake you one stop before by default.';

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
}
