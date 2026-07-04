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
        return 'GPS signal weak — showing last known position on $selectedLine';
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
      if (snapshot.tripConcern == TripPatternConcern.unlikelyRoute) {
        return 'Stop count looks off for this direction on $selectedLine. '
            'You may not be on this trip yet.';
      }
      if (!snapshot.directionLocked && snapshot.directionLabel != null) {
        return 'Locking direction: ${snapshot.directionLabel}…';
      }
      if (snapshot.stopsRemaining == 0) {
        return 'At your stop on $selectedLine';
      }
      return 'Waking by stops on $selectedLine';
    }

    if (isMonitoring) {
      return TripUxCopy.confirmingRoute;
    }

    return 'Tap Start when you are on board.';
  }

  static WakeAlertCopy forTransitAlarm({
    required TransitModeSnapshot snapshot,
    required TransitModeWakeSetting wakeSetting,
    List<TransitStop> segmentStops = const [],
    String? fallbackDestinationName,
  }) {
    final destinationName = GtfsStopNameUtils.stationDisplayName(
      snapshot.destinationStop?.stopName ??
          fallbackDestinationName ??
          'your destination',
    );
    final currentStopName = snapshot.currentStop != null
        ? GtfsStopNameUtils.stationDisplayName(snapshot.currentStop!.stopName)
        : destinationName;

    final uiHeadline = wakeSetting == TransitModeWakeSetting.atDestination
        ? TripUxCopy.timeToGetOffHeadline
        : TripUxCopy.getReadyHeadline;
    final headline = TripUxCopy.destinationIsYourStop(destinationName);

    final wearSubline = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination => 'Time to get off',
      TransitModeWakeSetting.oneStopBefore => '1 stop to go',
      TransitModeWakeSetting.twoStopsBefore => '2 stops to go',
    };

    final secondaryLine = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination => null,
      TransitModeWakeSetting.oneStopBefore => TripUxCopy.stayOnBoardOneMoreStop,
      TransitModeWakeSetting.twoStopsBefore => TripUxCopy.stayOnBoardTwoMoreStops,
    };

    const detailMessage = _alarmDismissFooter;

    final ttsPhrase = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination =>
        'Heads up! Your stop $destinationName is here.',
      TransitModeWakeSetting.oneStopBefore =>
        'Heads up! Get ready to get off at $destinationName, one stop away.',
      TransitModeWakeSetting.twoStopsBefore =>
        'Heads up! Get ready to get off at $destinationName, two stops away.',
    };

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
    final ttsPhrase = 'Heads up! Approaching $displayName.';

    return WakeAlertCopy(
      uiHeadline: TripUxCopy.getReadyHeadline,
      headline: TripUxCopy.destinationIsYourStop(displayName),
      primaryStopName: displayName,
      currentStopName: displayName,
      detailMessage: _alarmDismissFooter,
      ttsPhrase: ttsPhrase,
      wearSubline: 'Within wake radius',
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
