import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/history_service.dart';
import '../repositories/station_repository.dart';

/// Service locator container instance
final GetIt locator = GetIt.instance;

/// Set up dependency injection registrations.
/// Must be initialized before [runApp] is called.
Future<void> setupLocator() async {
  // Services
  locator.registerLazySingleton<ApiService>(() => DioApiService());
  locator.registerLazySingleton<FavoritesService>(
    () => SharedPreferencesFavoritesService(),
  );
  locator.registerLazySingleton<HistoryService>(
    () => SharedPreferencesHistoryService(),
  );

  // Repositories
  locator.registerLazySingleton<StationRepository>(
    () => StationRepositoryImpl(
      locator<ApiService>(),
      locator<FavoritesService>(),
      locator<HistoryService>(),
    ),
  );
}
