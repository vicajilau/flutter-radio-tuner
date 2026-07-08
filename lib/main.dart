import 'package:flutter/material.dart';
import 'package:flutter_radio_tuner/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'core/services/audio_initializer.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'core/services/favorites_service.dart';
import 'core/services/history_service.dart';
import 'core/repositories/station_repository.dart';
import 'providers/favorites_provider.dart';
import 'providers/radio_provider.dart';
import 'ui/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioInitializer.initialize();
  runApp(const RadioApp());
}

/// The main entry point class of the application (RadioApp).
/// Configures the dependency injection tree, initializes state providers,
/// and defines the visual theme and the initial screen of the app.
class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = DioApiService();
    final favoritesService = SharedPreferencesFavoritesService();
    final historyService = SharedPreferencesHistoryService();
    final stationRepository = StationRepositoryImpl(
      apiService,
      favoritesService,
      historyService,
    );

    return MultiProvider(
      providers: [
        Provider<StationRepository>.value(value: stationRepository),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(stationRepository),
        ),
        ChangeNotifierProvider(create: (_) => RadioProvider(stationRepository)),
      ],
      child: MaterialApp(
        title: 'Labhouse FM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashScreen(),
      ),
    );
  }
}
