import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../services/hive_service.dart';
import '../repositories/station_repository.dart';

part 'di_providers.g.dart';

/// Provider exposing the [HiveService] singleton.
@Riverpod(keepAlive: true)
HiveService hiveService(Ref ref) {
  return HiveService();
}

/// Provider exposing the [ApiService] implementation.
@Riverpod(keepAlive: true)
ApiService apiService(Ref ref) {
  return DioApiService(ref.watch(hiveServiceProvider));
}

/// Provider exposing the [FavoritesService] implementation.
@Riverpod(keepAlive: true)
FavoritesService favoritesService(Ref ref) {
  return HiveFavoritesService(ref.watch(hiveServiceProvider));
}

/// Provider exposing the [HistoryService] implementation.
@Riverpod(keepAlive: true)
HistoryService historyService(Ref ref) {
  return HiveHistoryService(ref.watch(hiveServiceProvider));
}

/// Provider exposing the [StationRepository] implementation.
/// Resolves its dependent services using Riverpod's `ref.watch`.
@Riverpod(keepAlive: true)
StationRepository stationRepository(Ref ref) {
  return StationRepositoryImpl(
    ref.watch(apiServiceProvider),
    ref.watch(favoritesServiceProvider),
    ref.watch(historyServiceProvider),
  );
}
