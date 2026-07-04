import '../models/trip_pattern_concern.dart';
import '../models/transit_mode_snapshot.dart';
import '../models/transit_mode_wake_setting.dart';
import '../models/transit_stop.dart';
import '../utils/gtfs_stop_name_utils.dart';

/// User-facing copy for wake alerts on phone and Wear OS.
class WakeAlertCopy {
  const WakeAlertCopy({
    required this.headline,
    required this.primaryStopName,
    required this.detailMessage,
    required this.ttsPhrase,
    this.secondaryLine,
    this.wearSubline,
  });

  /// Dialog / notification title line.
  final String headline;

  /// Prominent stop name (wake stop, not always the final destination).
  final String primaryStopName;

  /// Body text under the stop name.
  final String detailMessage;

  /// Spoken by TTS during the alarm loop.
  final String ttsPhrase;

  /// Optional subtitle, e.g. final destination when waking early.
  final String? secondaryLine;

  /// Second line on Wear alarm screen (avoids duplicating the stop name).
  final String? wearSubline;
}

abstract final class TransitWakeMessage {
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
      return 'Waiting to lock onto your route — $selectedLine';
    }

    return 'Tap Start to begin tracking your ride.';
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

    // The rider ALWAYS gets off at their chosen destination. The wake setting
    // only controls how much of a heads-up they get (at the stop, or 1/2 stops
    // early to prepare) — so the copy must never tell them to get off earlier.
    final headline = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination => 'Arriving at $destinationName',
      TransitModeWakeSetting.oneStopBefore =>
        '$destinationName — 1 stop to go',
      TransitModeWakeSetting.twoStopsBefore =>
        '$destinationName — 2 stops to go',
    };

    // Reassure early-wake riders to stay on board until their actual stop.
    final secondaryLine = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination => null,
      TransitModeWakeSetting.oneStopBefore ||
      TransitModeWakeSetting.twoStopsBefore =>
        'Stay on until $destinationName',
    };

    final detailMessage = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination =>
        'Your stop $destinationName is here. '
            'Voice alert and vibration continue until you dismiss.',
      TransitModeWakeSetting.oneStopBefore =>
        'Get ready to get off at $destinationName, 1 stop away. '
            'Voice alert and vibration continue until you dismiss.',
      TransitModeWakeSetting.twoStopsBefore =>
        'Get ready to get off at $destinationName, 2 stops away. '
            'Voice alert and vibration continue until you dismiss.',
    };

    final ttsPhrase = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination =>
        'Heads up! Your stop $destinationName is here.',
      TransitModeWakeSetting.oneStopBefore =>
        'Heads up! Get ready to get off at $destinationName, one stop away.',
      TransitModeWakeSetting.twoStopsBefore =>
        'Heads up! Get ready to get off at $destinationName, two stops away.',
    };

    final wearSubline = switch (wakeSetting) {
      TransitModeWakeSetting.atDestination => 'Time to get off',
      TransitModeWakeSetting.oneStopBefore => '1 stop to go',
      TransitModeWakeSetting.twoStopsBefore => '2 stops to go',
    };

    return WakeAlertCopy(
      headline: headline,
      primaryStopName: destinationName,
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
    final headline = 'Approaching $destinationName';
    final detailMessage = transitFallback
        ? 'Distance wake — could not track your route, so waking by distance '
            'to $destinationName. Voice alert and vibration continue until you dismiss.'
        : 'Distance wake — within your wake radius of $destinationName. '
            'Voice alert and vibration continue until you dismiss.';
    final ttsPhrase = 'Heads up! Approaching $destinationName.';

    return WakeAlertCopy(
      headline: headline,
      primaryStopName: destinationName,
      detailMessage: detailMessage,
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
