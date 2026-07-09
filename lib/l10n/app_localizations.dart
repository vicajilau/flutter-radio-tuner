import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Placeholder text for the search input field on the home screen
  ///
  /// In en, this message translates to:
  /// **'Search stations, genres, tags...'**
  String get searchPlaceholder;

  /// Header for popular genres category list
  ///
  /// In en, this message translates to:
  /// **'Popular Genres'**
  String get popularGenres;

  /// Header for favorited radio stations list
  ///
  /// In en, this message translates to:
  /// **'Favorite Stations'**
  String get favoriteStations;

  /// Header for recently played history list
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// Header for recommended stations list
  ///
  /// In en, this message translates to:
  /// **'Recommended Stations'**
  String get recommendedStations;

  /// Header showing search query results
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// Empty state subtitle when no genre or search is selected
  ///
  /// In en, this message translates to:
  /// **'Select a genre to start exploring'**
  String get selectGenreToExplore;

  /// Title shown when the user has no favorited stations
  ///
  /// In en, this message translates to:
  /// **'No favorite stations yet'**
  String get noFavoritesYet;

  /// Subtitle shown when the user has no favorited stations
  ///
  /// In en, this message translates to:
  /// **'Your favorite stations will appear here'**
  String get favoritesSubtitle;

  /// Title shown when the history list is empty
  ///
  /// In en, this message translates to:
  /// **'No recently played stations'**
  String get noRecentlyPlayed;

  /// Subtitle shown when the history list is empty
  ///
  /// In en, this message translates to:
  /// **'Stations you listen to will appear here'**
  String get recentlyPlayedSubtitle;

  /// Title shown when no recommended stations are found
  ///
  /// In en, this message translates to:
  /// **'No recommended stations'**
  String get noRecommended;

  /// Subtitle shown when no recommended stations are found
  ///
  /// In en, this message translates to:
  /// **'Check back later for recommendations'**
  String get recommendedSubtitle;

  /// Header title of the player screen
  ///
  /// In en, this message translates to:
  /// **'NOW STREAMING'**
  String get nowStreaming;

  /// Text shown if the player is opened with no active station
  ///
  /// In en, this message translates to:
  /// **'No station selected.'**
  String get noStationSelected;

  /// Status text showing remaining sleep timer duration
  ///
  /// In en, this message translates to:
  /// **'Sleep in {time}'**
  String sleepIn(String time);

  /// Toast message when the homepage url is empty
  ///
  /// In en, this message translates to:
  /// **'No website available for this station.'**
  String get noWebsite;

  /// Toast message when the homepage URL parsing fails
  ///
  /// In en, this message translates to:
  /// **'Invalid station website URL.'**
  String get invalidWebsite;

  /// Toast message when the system fails to open the browser
  ///
  /// In en, this message translates to:
  /// **'Could not open: {url}'**
  String couldNotOpen(String url);

  /// Button text to clear active search query and tags
  ///
  /// In en, this message translates to:
  /// **'Clear Search & Filters'**
  String get clearSearchAndFilters;

  /// Empty state query match text
  ///
  /// In en, this message translates to:
  /// **'No stations found matching \"{query}\"'**
  String noStationsFoundForQuery(String query);

  /// Empty state category match text
  ///
  /// In en, this message translates to:
  /// **'No stations found in category \"{tag}\"'**
  String noStationsFoundForCategory(String tag);

  /// Empty state general text when query and tag are empty but list is empty
  ///
  /// In en, this message translates to:
  /// **'No stations found matching the current filters'**
  String get noStationsFoundForFilters;

  /// Title of the sleep timer configuration bottom sheet
  ///
  /// In en, this message translates to:
  /// **'SLEEP TIMER'**
  String get sleepTimer;

  /// Subtitle of the sleep timer configuration bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Automatically stop playback after duration'**
  String get sleepTimerSubtitle;

  /// Cancel option in sleep timer presets
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Player loading state indicator
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// Player buffering state indicator
  ///
  /// In en, this message translates to:
  /// **'Buffering...'**
  String get buffering;

  /// Player live playing status message
  ///
  /// In en, this message translates to:
  /// **'Playing Live'**
  String get playingLive;

  /// Player paused status message
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// Detailed buffering status message
  ///
  /// In en, this message translates to:
  /// **'Buffering stream...'**
  String get bufferingStream;

  /// Splash screen loading status message
  ///
  /// In en, this message translates to:
  /// **'Resolving radio nodes...'**
  String get resolvingNodes;

  /// Error message when radio server is offline
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// General empty state message when list is empty
  ///
  /// In en, this message translates to:
  /// **'No Stations Found'**
  String get noStationsFound;

  /// Subtitle encouraging user to change query
  ///
  /// In en, this message translates to:
  /// **'Try searching for a different name, genre, or tag.'**
  String get searchEmptySubtitle;

  /// Subtitle when backend returns zero results
  ///
  /// In en, this message translates to:
  /// **'No stations available right now.'**
  String get noStationsAvailable;

  /// Button to retry connecting to the radio server
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// Reset search text button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Slogan tagline of the application
  ///
  /// In en, this message translates to:
  /// **'PREMIUM RADIO TUNER'**
  String get appTagline;

  /// Slogan displayed on the home page app bar header
  ///
  /// In en, this message translates to:
  /// **'Stream the world\'s music'**
  String get streamWorldsMusic;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Radio Tuner'**
  String get appTitle;

  /// Error message when device has no internet access
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// Buffering status when internet reconnection is active
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// Error message when radio stream fails to load
  ///
  /// In en, this message translates to:
  /// **'Unable to play this station. The stream may be offline.'**
  String get streamOffline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
