import 'package:geolocator/geolocator.dart';

import '../models/gtfs_station.dart';
import '../models/transit_stop.dart';
import 'gtfs_stop_name_utils.dart';

/// Groups GTFS platform stops into user-facing stations.
abstract final class GtfsStationUtils {
  /// Max distance between platforms treated as the same station.
  static const clusterRadiusMeters = 400;

  /// Decimal places for lat/lon in [stationKey] (~1.1 km at equator).
  static const keyCoordinateDecimals = 2;

  static String stationKey(String displayName, double lat, double lon) {
    final roundedLat = lat.toStringAsFixed(keyCoordinateDecimals);
    final roundedLon = lon.toStringAsFixed(keyCoordinateDecimals);
    return '${displayName.toLowerCase()}|$roundedLat|$roundedLon';
  }

  static String stationKeyForStop(TransitStop stop) {
    final displayName = GtfsStopNameUtils.stationDisplayName(stop.stopName);
    return stationKey(displayName, stop.latitude, stop.longitude);
  }

  static GtfsStation stationFromStop(TransitStop stop) {
    final name = GtfsStopNameUtils.stationDisplayName(stop.stopName);
    return GtfsStation(
      stationKey: stationKey(name, stop.latitude, stop.longitude),
      name: name,
      latitude: stop.latitude,
      longitude: stop.longitude,
      representativeStop: stop,
    );
  }

  static List<GtfsStation> dedupeStopsToStations(
    List<TransitStop> stops, {
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final clusters = <_StationCluster>[];

    for (final stop in stops) {
      final displayName = GtfsStopNameUtils.stationDisplayName(stop.stopName);
      if (normalizedQuery.isNotEmpty &&
          !displayName.toLowerCase().contains(normalizedQuery)) {
        continue;
      }

      _StationCluster? match;
      for (final cluster in clusters) {
        if (cluster.displayName.toLowerCase() != displayName.toLowerCase()) {
          continue;
        }
        if (cluster.distanceTo(stop.latitude, stop.longitude) <=
            clusterRadiusMeters) {
          match = cluster;
          break;
        }
      }

      if (match != null) {
        match.add(stop);
      } else {
        clusters.add(_StationCluster(displayName, stop));
      }
    }

    final stations = clusters.map((cluster) => cluster.toStation()).toList()
      ..sort(
        (a, b) => a.representativeStop.stopSequence
            .compareTo(b.representativeStop.stopSequence),
      );
    return stations;
  }
}

class _StationCluster {
  _StationCluster(this.displayName, TransitStop first)
      : _stops = [first],
        _latSum = first.latitude,
        _lonSum = first.longitude;

  final String displayName;
  final List<TransitStop> _stops;
  double _latSum;
  double _lonSum;

  void add(TransitStop stop) {
    _stops.add(stop);
    _latSum += stop.latitude;
    _lonSum += stop.longitude;
  }

  double distanceTo(double lat, double lon) {
    return Geolocator.distanceBetween(
      _latSum / _stops.length,
      _lonSum / _stops.length,
      lat,
      lon,
    );
  }

  GtfsStation toStation() {
    final count = _stops.length;
    final lat = _latSum / count;
    final lon = _lonSum / count;
    final representative = _pickRepresentativeStop();
    return GtfsStation(
      stationKey: GtfsStationUtils.stationKey(displayName, lat, lon),
      name: displayName,
      latitude: lat,
      longitude: lon,
      representativeStop: representative,
    );
  }

  TransitStop _pickRepresentativeStop() {
    if (_stops.length == 1) {
      return _stops.first;
    }

    final sorted = List<TransitStop>.from(_stops)
      ..sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    return sorted.first;
  }
}
