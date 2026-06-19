import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/transit_line.dart';
import '../models/transit_station.dart';

class TransitDataService {
  final Map<String, TransitLine> _cache = {};

  String _cacheKey({
    required String country,
    required String transitSystem,
    required String lineName,
  }) {
    return '$country|$transitSystem|$lineName';
  }

  String _assetPath({
    required String country,
    required String transitSystem,
    required String lineName,
  }) {
    final systemSegment = transitSystem.replaceAll(' ', '_');
    final lineSegment = lineName.replaceAll(' ', '_');
    return 'assets/transit/$country/$systemSegment/$lineSegment.json';
  }

  Future<TransitLine?> loadLine({
    required String country,
    required String transitSystem,
    required String lineName,
  }) async {
    final cacheKey = _cacheKey(
      country: country,
      transitSystem: transitSystem,
      lineName: lineName,
    );

    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      final assetPath = _assetPath(
        country: country,
        transitSystem: transitSystem,
        lineName: lineName,
      );
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final line = TransitLine.fromJson(decoded);
      _cache[cacheKey] = line;
      return line;
    } catch (_) {
      return null;
    }
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
