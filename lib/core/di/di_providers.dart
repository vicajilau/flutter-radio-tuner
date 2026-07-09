import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../repositories/station_repository.dart';

/// Provider exposing the [ApiService] implementation.
final apiServiceProvider = Provider<ApiService>((ref) {
  return DioApiService();
});

/// Provider exposing the [FavoritesService] implementation.
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return SharedPreferencesFavoritesService();
});

/// Provider exposing the [HistoryService] implementation.
final historyServiceProvider = Provider<HistoryService>((ref) {
  return SharedPreferencesHistoryService();
});

/// Provider exposing the [StationRepository] implementation.
/// Resolves its dependent services using Riverpod's `ref.watch`.
final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepositoryImpl(
    ref.watch(apiServiceProvider),
    ref.watch(favoritesServiceProvider),
    ref.watch(historyServiceProvider),
  );
});
