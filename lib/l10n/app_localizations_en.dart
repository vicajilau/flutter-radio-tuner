// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchPlaceholder => 'Search stations, genres, tags...';

  @override
  String get popularGenres => 'Popular Genres';

  @override
  String get favoriteStations => 'Favorite Stations';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get recommendedStations => 'Recommended Stations';

  @override
  String get searchResults => 'Search Results';

  @override
  String get selectGenreToExplore => 'Select a genre to start exploring';

  @override
  String get noFavoritesYet => 'No favorite stations yet';

  @override
  String get favoritesSubtitle => 'Your favorite stations will appear here';

  @override
  String get noRecentlyPlayed => 'No recently played stations';

  @override
  String get recentlyPlayedSubtitle =>
      'Stations you listen to will appear here';

  @override
  String get noRecommended => 'No recommended stations';

  @override
  String get recommendedSubtitle => 'Check back later for recommendations';

  @override
  String get nowStreaming => 'NOW STREAMING';

  @override
  String get noStationSelected => 'No station selected.';

  @override
  String sleepIn(String time) {
    return 'Sleep in $time';
  }

  @override
  String get noWebsite => 'No website available for this station.';

  @override
  String get invalidWebsite => 'Invalid station website URL.';

  @override
  String couldNotOpen(String url) {
    return 'Could not open: $url';
  }

  @override
  String get clearSearchAndFilters => 'Clear Search & Filters';

  @override
  String noStationsFoundForQuery(String query) {
    return 'No stations found matching \"$query\"';
  }

  @override
  String noStationsFoundForCategory(String tag) {
    return 'No stations found in category \"$tag\"';
  }

  @override
  String get noStationsFoundForFilters =>
      'No stations found matching the current filters';

  @override
  String get sleepTimer => 'SLEEP TIMER';

  @override
  String get sleepTimerSubtitle => 'Automatically stop playback after duration';

  @override
  String get cancel => 'Cancel';

  @override
  String get connecting => 'Connecting...';

  @override
  String get buffering => 'Buffering...';

  @override
  String get playingLive => 'Playing Live';

  @override
  String get paused => 'Paused';

  @override
  String get bufferingStream => 'Buffering stream...';

  @override
  String get resolvingNodes => 'Resolving radio nodes...';

  @override
  String get connectionError => 'Connection Error';

  @override
  String get noStationsFound => 'No Stations Found';

  @override
  String get searchEmptySubtitle =>
      'Try searching for a different name, genre, or tag.';

  @override
  String get noStationsAvailable => 'No stations available right now.';

  @override
  String get retryConnection => 'Retry Connection';

  @override
  String get reset => 'Reset';

  @override
  String get appTagline => 'P R E M I U M   R A D I O   T U N E R';

  @override
  String get streamWorldsMusic => 'Stream the world\'s music';

  @override
  String get appTitle => 'Radio Tuner';

  @override
  String get noInternet => 'No internet connection';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get streamOffline =>
      'Unable to play this station. The stream may be offline.';
}
