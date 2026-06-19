import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/transit_line.dart';
import '../models/transit_station.dart';

class TransitLineLoadResult {
  const TransitLineLoadResult({
    required this.assetPath,
    this.line,
    this.error,
    this.fromCache = false,
  });

  final String assetPath;
  final TransitLine? line;
  final String? error;
  final bool fromCache;

  bool get isSuccess => line != null && error == null;
  int get stationCount => line?.stations.length ?? 0;
}

class TransitDataService {
  final Map<String, TransitLine> _cache = {};

  String cacheKey({
    required String country,
    required String transitSystem,
    required String lineName,
  }) {
    return '$country|$transitSystem|$lineName';
  }

  String assetPath({
    required String country,
    required String transitSystem,
    required String lineName,
  }) {
    final systemSegment = transitSystem.replaceAll(' ', '_');
    final lineSegment = lineName.replaceAll(' ', '_');
    return 'assets/transit/$country/$systemSegment/$lineSegment.json';
  }

  Future<TransitLineLoadResult> loadLine({
    required String country,
    required String transitSystem,
    required String lineName,
  }) async {
    final path = assetPath(
      country: country,
      transitSystem: transitSystem,
      lineName: lineName,
    );
    final key = cacheKey(
      country: country,
      transitSystem: transitSystem,
      lineName: lineName,
    );

    final cached = _cache[key];
    if (cached != null) {
      debugPrint(
        'TransitDataService: cache hit for $path (${cached.stations.length} stations)',
      );
      return TransitLineLoadResult(
        assetPath: path,
        line: cached,
        fromCache: true,
      );
    }

    debugPrint('TransitDataService: loading $path');

    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final line = TransitLine.fromJson(decoded);
      _cache[key] = line;

      debugPrint(
        'TransitDataService: loaded $path (${line.stations.length} stations)',
      );

      return TransitLineLoadResult(assetPath: path, line: line);
    } on FlutterError catch (error) {
      final message = 'Missing file: $path (${error.message})';
      debugPrint('TransitDataService: $message');
      return TransitLineLoadResult(assetPath: path, error: message);
    } catch (error) {
      final message = 'Failed to load $path: $error';
      debugPrint('TransitDataService: $message');
      return TransitLineLoadResult(assetPath: path, error: message);
    }
  }

  List<TransitStation> filterStations(
    List<TransitStation> stations,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return stations
        .where(
          (station) => station.name.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  TransitStation? getStationByName(TransitLine line, String name) {
    for (final station in line.stations) {
      if (station.name == name) {
        return station;
      }
    }
    return null;
  }

  TransitStation? getStationByOrder(TransitLine line, int stationOrder) {
    for (final station in line.stations) {
      if (station.stationOrder == stationOrder) {
        return station;
      }
    }
    return null;
  }

  TransitStation? getNextStation(TransitLine line, TransitStation station) {
    return getStationByOrder(line, station.stationOrder + 1);
  }

  TransitStation? getPreviousStation(TransitLine line, TransitStation station) {
    return getStationByOrder(line, station.stationOrder - 1);
  }
}
