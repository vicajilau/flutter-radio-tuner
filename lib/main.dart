import 'package:flutter/material.dart';
import 'package:flutter_radio_tuner/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/service_locator.dart';
import 'core/services/audio_initializer.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator(); // Initialize GetIt DI
  await AudioInitializer.initialize();
  runApp(const ProviderScope(child: RadioApp()));
}

/// The main entry point class of the application (RadioApp).
/// Configures the dependency injection tree, initializes state providers,
/// and defines the visual theme and the initial screen of the app.
class RadioApp extends StatelessWidget {
  const RadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Labhouse FM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(),
    );
  }
}
