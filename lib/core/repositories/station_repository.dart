import '../../models/station_model.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';

/// Interface for the radio station repository.
/// Defines the data access contract for fetching popular stations,
/// filtering tags, and managing playback history and favorites.
abstract class StationRepository {
  Future<void> initialize();
  Future<List<Station>> getPopularStations({bool forceRefresh});
  Future<List<String>> getPopularTags({bool forceRefresh});
  Future<List<Station>> searchStations({String? query, String? tag});
  Future<List<Station>> getFavorites();
  Future<bool> isFavorite(String stationuuid);
  Future<void> addFavorite(Station station);
  Future<void> removeFavorite(String stationuuid);
  Future<void> saveFavorites(List<Station> stations);
  Future<List<Station>> getHistory();
  Future<void> addHistory(Station station);
  Future<List<Station>> getCachedPopularStations();
  Future<List<String>> getCachedPopularTags();
}

/// Concrete implementation of [StationRepository].
/// Coordinates data retrieval from [ApiService], [FavoritesService],
/// and [HistoryService].
class StationRepositoryImpl implements StationRepository {
  final ApiService _apiService;
  final FavoritesService _favoritesService;
  final HistoryService _historyService;

  StationRepositoryImpl(
    this._apiService,
    this._favoritesService,
    this._historyService,
  );

  @override
  Future<void> initialize() async {
    await _apiService.initialize();
  }

  @override
  Future<List<Station>> getPopularStations({bool forceRefresh = false}) async {
    return _apiService.getTopStations(limit: 20, forceRefresh: forceRefresh);
  }

  @override
  Future<List<String>> getPopularTags({bool forceRefresh = false}) async {
    return _apiService.getTopTags(limit: 15, forceRefresh: forceRefresh);
  }

  @override
  Future<List<Station>> searchStations({String? query, String? tag}) async {
    return _apiService.searchStations(name: query, tag: tag, limit: 60);
  }

  @override
  Future<List<Station>> getFavorites() async {
    return _favoritesService.getFavorites();
  }

  @override
  Future<bool> isFavorite(String stationuuid) async {
    return _favoritesService.isFavorite(stationuuid);
  }

  @override
  Future<void> addFavorite(Station station) async {
    await _favoritesService.addFavorite(station);
  }

  @override
  Future<void> removeFavorite(String stationuuid) async {
    await _favoritesService.removeFavorite(stationuuid);
  }

  @override
  Future<void> saveFavorites(List<Station> stations) async {
    await _favoritesService.saveFavorites(stations);
  }

  @override
  Future<List<Station>> getHistory() async {
    return _historyService.getHistory();
  }

  @override
  Future<void> addHistory(Station station) async {
    await _historyService.addHistory(station);
  }

  @override
  Future<List<Station>> getCachedPopularStations() async {
    return _apiService.getCachedTopStations(limit: 20);
  }

  @override
  Future<List<String>> getCachedPopularTags() async {
    return _apiService.getCachedTopTags(limit: 15);
  }
}
