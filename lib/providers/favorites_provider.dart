import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/di/di_providers.dart';
import '../core/repositories/station_repository.dart';
import '../models/station_model.dart';

part 'favorites_provider.g.dart';

/// State class containing the favorites data and loading indicator.
class FavoritesState {
  final List<Station> favorites;
  final bool isLoading;

  const FavoritesState({required this.favorites, required this.isLoading});

  FavoritesState copyWith({List<Station>? favorites, bool? isLoading}) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier that manages the user's favorite radio stations.
/// Persists favorite selections across app launches using [StationRepository].
@Riverpod(keepAlive: true)
class Favorites extends _$Favorites {
  late final StationRepository _repository;

  @override
  FavoritesState build() {
    _repository = ref.watch(stationRepositoryProvider);
    // Load favorites from local storage
    Future.microtask(() => loadFavorites());
    return const FavoritesState(favorites: [], isLoading: true);
  }

  /// Load favorites from repository.
  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    try {
      final favoritesList = await _repository.getFavorites();
      state = state.copyWith(favorites: favoritesList, isLoading: false);
    } catch (_) {
      state = state.copyWith(favorites: [], isLoading: false);
    }
  }

  /// Check if a station is favorited.
  bool isFavorite(String stationuuid) {
    return state.favorites.any((s) => s.stationuuid == stationuuid);
  }

  /// Toggle favorite status of a station.
  Future<void> toggleFavorite(Station station) async {
    final bool favorited = isFavorite(station.stationuuid);
    if (favorited) {
      final updatedList = state.favorites
          .where((s) => s.stationuuid != station.stationuuid)
          .toList();
      state = state.copyWith(favorites: updatedList);
      await _repository.removeFavorite(station.stationuuid);
    } else {
      final updatedList = [...state.favorites, station];
      state = state.copyWith(favorites: updatedList);
      await _repository.addFavorite(station);
    }
  }

  /// Reorders favorite stations in-memory and persists the new order.
  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final currentList = List<Station>.from(state.favorites);
    final Station movedStation = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, movedStation);

    state = state.copyWith(favorites: currentList);
    await _repository.saveFavorites(currentList);
  }
}
