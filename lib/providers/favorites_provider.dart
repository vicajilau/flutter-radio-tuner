import 'package:flutter/foundation.dart';
import '../../models/station_model.dart';
import '../core/repositories/station_repository.dart';

/// ChangeNotifier that manages the user's favorite radio stations.
/// Observes, updates, and persists favorite selections across app launches.
class FavoritesProvider with ChangeNotifier {
  final StationRepository _repository;
  List<Station> _favorites = [];
  bool _isLoading = false;

  List<Station> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoritesProvider(this._repository) {
    loadFavorites();
  }

  /// Load favorites from local storage.
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _repository.getFavorites();
    } catch (_) {
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if a station is favorited.
  bool isFavorite(String stationuuid) {
    return _favorites.any((s) => s.stationuuid == stationuuid);
  }

  /// Toggle favorite status of a station.
  Future<void> toggleFavorite(Station station) async {
    final bool favorited = isFavorite(station.stationuuid);
    if (favorited) {
      _favorites.removeWhere((s) => s.stationuuid == station.stationuuid);
      notifyListeners();
      await _repository.removeFavorite(station.stationuuid);
    } else {
      _favorites.add(station);
      notifyListeners();
      await _repository.addFavorite(station);
    }
  }
}
