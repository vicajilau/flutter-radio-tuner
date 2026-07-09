import 'package:hive_ce_flutter/hive_flutter.dart';

/// Service responsible for Hive database lifecycle, box access, and initialization.
/// Encapsulates all Hive direct database calls to enable cleaner dependency injection,
/// decoupling implementation details, and robust unit testing.
class HiveService {
  /// Name of the box storing favorite stations.
  static const String favoritesBoxName = 'favorite_stations';

  /// Name of the box storing recently played history.
  static const String historyBoxName = 'played_history_stations';

  /// Name of the box storing cached API responses.
  static const String cacheBoxName = 'radio_api_cache';

  /// Initializes the Hive database and opens the default storage boxes.
  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(favoritesBoxName);
    await Hive.openBox<String>(historyBoxName);
    await Hive.openBox<String>(cacheBoxName);
  }

  // --- Favorites Box Operations ---

  /// Gets all values from the favorites box.
  List<String> getFavoritesValues() {
    if (!Hive.isBoxOpen(favoritesBoxName)) return [];
    return Hive.box<String>(favoritesBoxName).values.toList();
  }

  /// Checks if a station exists in favorites.
  bool favoritesContainKey(String key) {
    if (!Hive.isBoxOpen(favoritesBoxName)) return false;
    return Hive.box<String>(favoritesBoxName).containsKey(key);
  }

  /// Puts a station into the favorites box.
  Future<void> putFavorite(String key, String value) async {
    if (!Hive.isBoxOpen(favoritesBoxName)) return;
    await Hive.box<String>(favoritesBoxName).put(key, value);
  }

  /// Deletes a station from the favorites box.
  Future<void> deleteFavorite(String key) async {
    if (!Hive.isBoxOpen(favoritesBoxName)) return;
    await Hive.box<String>(favoritesBoxName).delete(key);
  }

  /// Clears all entries from the favorites box.
  Future<void> clearFavorites() async {
    if (!Hive.isBoxOpen(favoritesBoxName)) return;
    await Hive.box<String>(favoritesBoxName).clear();
  }

  // --- History Box Operations ---

  /// Gets a value from the history box.
  String? getHistoryValue(String key) {
    if (!Hive.isBoxOpen(historyBoxName)) return null;
    return Hive.box<String>(historyBoxName).get(key);
  }

  /// Puts a value into the history box.
  Future<void> putHistoryValue(String key, String value) async {
    if (!Hive.isBoxOpen(historyBoxName)) return;
    await Hive.box<String>(historyBoxName).put(key, value);
  }

  /// Deletes a value from the history box.
  Future<void> deleteHistoryValue(String key) async {
    if (!Hive.isBoxOpen(historyBoxName)) return;
    await Hive.box<String>(historyBoxName).delete(key);
  }

  // --- Cache Box Operations ---

  /// Gets a value from the cache box.
  String? getCacheValue(String key) {
    if (!Hive.isBoxOpen(cacheBoxName)) return null;
    return Hive.box<String>(cacheBoxName).get(key);
  }

  /// Puts a value into the cache box.
  Future<void> putCacheValue(String key, String value) async {
    if (!Hive.isBoxOpen(cacheBoxName)) return;
    await Hive.box<String>(cacheBoxName).put(key, value);
  }
}
