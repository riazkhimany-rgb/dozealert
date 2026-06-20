import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/favorite_destination.dart';
import '../services/preferences_service.dart';

class DestinationHistoryProvider extends ChangeNotifier {
  DestinationHistoryProvider(this._preferencesService);

  final PreferencesService _preferencesService;

  List<Destination> _recents = const [];
  List<FavoriteDestination> _favorites = const [];

  List<Destination> get recents => _recents;
  List<FavoriteDestination> get favorites => _favorites;

  Future<void> load() async {
    _recents = await _preferencesService.loadRecentStations();
    _favorites = await _preferencesService.loadFavorites();
    if (_favorites.isEmpty) {
      _favorites = await _preferencesService.seedFavoritesIfEmpty();
    }
    notifyListeners();
  }

  Future<void> recordRecent(Destination destination) async {
    _recents = await _preferencesService.addRecentStation(destination);
    notifyListeners();
  }

  Future<void> addFavorite(
    Destination destination, {
    List<String> badges = const [],
  }) async {
    _favorites = await _preferencesService.addFavorite(
      FavoriteDestination(destination: destination, badges: badges),
    );
    notifyListeners();
  }

  Future<void> removeFavorite(Destination destination) async {
    _favorites = await _preferencesService.removeFavorite(destination);
    notifyListeners();
  }

  bool isFavorite(Destination destination) {
    return _favorites.any((item) => item.matches(destination));
  }
}
