import '../models/trip_pattern_concern.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_stop.dart';
import '../utils/gtfs_stop_name_utils.dart';
import 'trip_ux_copy.dart';

/// User-facing copy for wake alerts on phone and Wear OS.
class WakeAlertCopy {
  const WakeAlertCopy({
    required this.uiHeadline,
    required this.headline,
    required this.primaryStopName,
    required this.currentStopName,
    required this.detailMessage,
    required this.ttsPhrase,
    this.secondaryLine,
    this.wearSubline,
  });

  /// Large alarm screen headline (e.g. GET READY).
  final String uiHeadline;

  /// Destination-focused line under the headline.
  final String headline;

  /// Selected destination (Wear sync / alarmStopName).
  final String primaryStopName;

  /// Stop the rider is at now — phone alarm cyan accent line.
  final String currentStopName;

  /// Footer under the Dismiss button on the phone alarm screen.
  final String detailMessage;

  /// Spoken by TTS during the alarm loop.
  final String ttsPhrase;

  /// Optional reassurance between accent stop and Dismiss (e.g. "Stay on board").
  final String? secondaryLine;

  /// Status under the destination on phone; gray line on Wear ("1 stop to go").
  final String? wearSubline;
}

/// Alarm copy pushed to Wear OS when a background transit wake fires.
class WearAlarmSyncFields {
  const WearAlarmSyncFields({
    required this.uiHeadline,
    required this.headline,
    required this.subline,
    required this.stopName,
  });

  final String uiHeadline;
  final String headline;
  final String subline;
  final String stopName;
}

abstract final class AlarmTtsCopy {
  /// Default when no custom phrase is passed to [AlarmService.playApproachAlarm].
  static const defaultApproaching = 'Heads up! Approaching destination.';

  /// Transit wake: rider should get off now ([stopsLeft] == 0).
  static String transitAtDestination(String destinationName) =>
      'Heads up! Your stop $destinationName is here.';

  /// Transit wake: [stopsLeft] stops before destination.
  static String transitStopsAway({
    required String destinationName,
    required int stopsLeft,
  }) {
    if (stopsLeft == 1) {
      return 'Heads up! Get ready to get off at $destinationName, one stop away.';
    }
    return 'Heads up! Get ready to get off at $destinationName, $stopsLeft stops away.';
  }

  /// Non-transit / distance-based wake.
  static String distanceApproaching(String destinationName) =>
      'Heads up! Approaching $destinationName.';
}

abstract final class TransitWakeMessage {
  static const _alarmDismissFooter = TripUxCopy.alarmContinuesUntilDismiss;

  static String forHome({
    required bool transitModeEnabled,
    required bool gtfsReady,
    required TransitModeSnapshot snapshot,
    required bool isMonitoring,
    String? selectedLine,
    bool gpsSignalLost = false,
  }) {
    if (!transitModeEnabled) {
      return 'Waking by distance to destination';
    }

    if (!gtfsReady) {
      return 'Download your transit stop list to wake by stops';
    }

    if (snapshot.isActive) {
      if (gpsSignalLost) {
        return TripUxCopy.gpsSignalWeakMessage(lineName: selectedLine);
      }
      if (snapshot.tripConcern == TripPatternConcern.wrongDirection) {
        final direction = snapshot.directionLabel;
        if (direction != null && direction.isNotEmpty) {
          return 'This trip may be the wrong direction ($direction). '
              'Check your line and direction on $selectedLine.';
        }
        return 'This trip may be the wrong direction on $selectedLine. '
            'Check your line and direction.';
      }
      if (!snapshot.directionLocked && snapshot.directionLabel != null) {
        return 'Locking direction: ${snapshot.directionLabel}…';
      }
      if (snapshot.stopsRemaining == 0) {
        return TripUxCopy.stopsRemainingLabel(
          0,
          style: StopsRemainingStyle.notification,
        );
      }
      return 'Waking by stops on $selectedLine';
    }

    if (isMonitoring) {
      return TripUxCopy.confirmingRoute;
    }

    return 'Tap Start when you are on board.';
  }

  /// Stop count shown on the alarm when wake-by-stops fires.
  ///
  /// The background isolate can trigger the wake one GPS tick ahead of the
  /// foreground snapshot. Cap inflated counts so "1 stop before" never reads
  /// as "2 more stops to go" on the alarm screen.
  static int stopsLeftForAlarmDisplay({
    required int stopsRemaining,
    required TransitModeWakeSetting wakeSetting,
  }) {
    if (wakeSetting == TransitModeWakeSetting.atDestination) {
      return stopsRemaining;
    }

    final wakeCount = wakeSetting.wakeStopCount;
    return stopsRemaining > wakeCount ? wakeCount : stopsRemaining;
  }

  /// Alarm fields for Wear OS / background wake when the foreground snapshot
  /// may still be one GPS tick behind the background evaluator.
  static WearAlarmSyncFields wearAlarmFieldsForWake({
    required int stopsRemaining,
    required TransitModeWakeSetting wakeSetting,
    required String destinationName,
  }) {
    final displayName = GtfsStopNameUtils.stationDisplayName(destinationName);
    final stopsLeft = stopsLeftForAlarmDisplay(
      stopsRemaining: stopsRemaining,
      wakeSetting: wakeSetting,
    );

    return WearAlarmSyncFields(
      uiHeadline: wakeSetting == TransitModeWakeSetting.atDestination &&
              stopsLeft == 0
          ? TripUxCopy.timeToGetOffHeadline
          : TripUxCopy.getReadyHeadline,
      headline: TripUxCopy.destinationIsYourStop(displayName),
      subline: TripUxCopy.stopsRemainingLabel(
        stopsLeft,
        style: StopsRemainingStyle.alarm,
      ),
      stopName: displayName,
    );
  }

  static WakeAlertCopy forTransitAlarm({
    required TransitModeSnapshot snapshot,
    required TransitModeWakeSetting wakeSetting,
    List<TransitStop> segmentStops = const [],
    String? fallbackDestinationName,
    int? stopsRemainingOverride,
  }) {
    final destinationName = GtfsStopNameUtils.stationDisplayName(
      snapshot.destinationStop?.stopName ??
          fallbackDestinationName ??
          'your destination',
    );
    final currentStopName = snapshot.currentStop != null
        ? GtfsStopNameUtils.stationDisplayName(snapshot.currentStop!.stopName)
        : destinationName;

    final stopsLeft = stopsLeftForAlarmDisplay(
      stopsRemaining: stopsRemainingOverride ?? snapshot.stopsRemaining,
      wakeSetting: wakeSetting,
    );
    final uiHeadline = wakeSetting == TransitModeWakeSetting.atDestination &&
            stopsLeft == 0
        ? TripUxCopy.timeToGetOffHeadline
        : TripUxCopy.getReadyHeadline;
    final headline = TripUxCopy.destinationIsYourStop(destinationName);

    final wearSubline = TripUxCopy.stopsRemainingLabel(
      stopsLeft,
      style: StopsRemainingStyle.alarm,
    );

    final secondaryLine = stopsLeft <= 0
        ? null
        : TripUxCopy.stayOnBoardForStopsRemaining(stopsLeft);

    const detailMessage = _alarmDismissFooter;

    final ttsPhrase = stopsLeft <= 0
        ? AlarmTtsCopy.transitAtDestination(destinationName)
        : AlarmTtsCopy.transitStopsAway(
            destinationName: destinationName,
            stopsLeft: stopsLeft,
          );

    return WakeAlertCopy(
      uiHeadline: uiHeadline,
      headline: headline,
      primaryStopName: destinationName,
      currentStopName: currentStopName,
      detailMessage: detailMessage,
      ttsPhrase: ttsPhrase,
      secondaryLine: secondaryLine,
      wearSubline: wearSubline,
    );
  }

  static WakeAlertCopy forDistanceAlarm({
    required String destinationName,
    bool transitFallback = false,
  }) {
    final displayName = GtfsStopNameUtils.stationDisplayName(destinationName);
    final ttsPhrase = AlarmTtsCopy.distanceApproaching(displayName);

    return WakeAlertCopy(
      uiHeadline: TripUxCopy.getReadyHeadline,
      headline: TripUxCopy.destinationIsYourStop(displayName),
      primaryStopName: displayName,
      currentStopName: displayName,
      detailMessage: _alarmDismissFooter,
      ttsPhrase: ttsPhrase,
      wearSubline: 'Within alert distance',
    );
  }

  /// Stop where the rider should get off for the chosen wake setting.
  static String? wakeStopNameFor({
    required TransitModeSnapshot snapshot,
    required int wakeStopCount,
    List<TransitStop> segmentStops = const [],
  }) {
    final destination = snapshot.destinationStop;
    if (destination == null) {
      return null;
    }

    if (wakeStopCount == 0) {
      return GtfsStopNameUtils.stationDisplayName(destination.stopName);
    }

    if (segmentStops.length > wakeStopCount) {
      final index = segmentStops.length - 1 - wakeStopCount;
      if (index >= 0) {
        return GtfsStopNameUtils.stationDisplayName(segmentStops[index].stopName);
      }
    }

    if (snapshot.stopsRemaining <= wakeStopCount &&
        snapshot.nextStop != null) {
      return GtfsStopNameUtils.stationDisplayName(snapshot.nextStop!.stopName);
    }

    return GtfsStopNameUtils.stationDisplayName(destination.stopName);
  }
}
