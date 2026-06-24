import 'package:flutter/material.dart';

import '../models/favorite_transit_line.dart';
import '../services/preferences_service.dart';

class FavoriteTransitLineProvider extends ChangeNotifier {
  FavoriteTransitLineProvider(this._preferencesService);

  final PreferencesService _preferencesService;

  List<FavoriteTransitLine> _favorites = const [];

  List<FavoriteTransitLine> get favorites => _favorites;

  Future<void> load() async {
    _favorites = await _preferencesService.loadFavoriteTransitLines();
    notifyListeners();
  }

  Future<void> add(FavoriteTransitLine favorite) async {
    _favorites = await _preferencesService.addFavoriteTransitLine(favorite);
    notifyListeners();
  }

  Future<void> remove(FavoriteTransitLine favorite) async {
    _favorites = await _preferencesService.removeFavoriteTransitLine(favorite);
    notifyListeners();
  }
}
