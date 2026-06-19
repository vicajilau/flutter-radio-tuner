import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/station_model.dart';

abstract class FavoritesService {
  Future<List<Station>> getFavorites();
  Future<bool> isFavorite(String stationuuid);
  Future<void> addFavorite(Station station);
  Future<void> removeFavorite(String stationuuid);
}

class SharedPreferencesFavoritesService implements FavoritesService {
  static const String _favoritesKey = 'favorite_stations';

  /// Get the list of saved favorite stations.
  @override
  Future<List<Station>> getFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favoritesJson = prefs.getStringList(_favoritesKey);

    if (favoritesJson == null) return [];

    return favoritesJson
        .map((jsonStr) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(jsonStr);
            return Station.fromJson(decoded);
          } catch (_) {
            return null;
          }
        })
        .whereType<Station>()
        .toList();
  }

  /// Check if a station is in favorites.
  @override
  Future<bool> isFavorite(String stationuuid) async {
    final favorites = await getFavorites();
    return favorites.any((s) => s.stationuuid == stationuuid);
  }

  /// Add a station to favorites.
  @override
  Future<void> addFavorite(Station station) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    if (!favorites.any((s) => s.stationuuid == station.stationuuid)) {
      favorites.add(station);
      final listJson = favorites.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_favoritesKey, listJson);
    }
  }

  /// Remove a station from favorites.
  @override
  Future<void> removeFavorite(String stationuuid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    favorites.removeWhere((s) => s.stationuuid == stationuuid);
    final listJson = favorites.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_favoritesKey, listJson);
  }
}
