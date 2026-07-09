import 'dart:convert';
import '../../models/station_model.dart';
import 'hive_service.dart';

/// Interface for the favorites local storage service.
/// Declares methods to retrieve, add, remove, and check favorite radio stations.
abstract class FavoritesService {
  Future<List<Station>> getFavorites();
  Future<bool> isFavorite(String stationuuid);
  Future<void> addFavorite(Station station);
  Future<void> removeFavorite(String stationuuid);
  Future<void> saveFavorites(List<Station> stations);
}

/// Hive-backed implementation of [FavoritesService]
/// for persistent storage of user's favorite radio stations.
class HiveFavoritesService implements FavoritesService {
  final HiveService _hiveService;

  HiveFavoritesService(this._hiveService);

  /// Get the list of saved favorite stations.
  @override
  Future<List<Station>> getFavorites() async {
    return _hiveService
        .getFavoritesValues()
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
    return _hiveService.favoritesContainKey(stationuuid);
  }

  /// Add a station to favorites.
  @override
  Future<void> addFavorite(Station station) async {
    await _hiveService.putFavorite(
      station.stationuuid,
      jsonEncode(station.toJson()),
    );
  }

  /// Remove a station from favorites.
  @override
  Future<void> removeFavorite(String stationuuid) async {
    await _hiveService.deleteFavorite(stationuuid);
  }

  /// Save entire list of favorite stations to persist reordering.
  @override
  Future<void> saveFavorites(List<Station> stations) async {
    await _hiveService.clearFavorites();
    for (final station in stations) {
      await _hiveService.putFavorite(
        station.stationuuid,
        jsonEncode(station.toJson()),
      );
    }
  }
}
