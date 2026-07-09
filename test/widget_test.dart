import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_radio_tuner/models/station_model.dart';
import 'package:flutter_radio_tuner/providers/favorites_provider.dart';
import 'package:flutter_radio_tuner/providers/playback_provider.dart';
import 'package:flutter_radio_tuner/providers/browser_provider.dart';
import 'package:flutter_radio_tuner/core/repositories/station_repository.dart';
import 'package:flutter_radio_tuner/core/di/service_locator.dart';

class MockStationRepository implements StationRepository {
  List<Station> favorites = [];
  List<Station> history = [];
  List<Station> popular = [];
  List<String> tags = [];
  bool isInitialized = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<List<Station>> getPopularStations() async {
    return popular;
  }

  @override
  Future<List<String>> getPopularTags() async {
    return tags;
  }

  @override
  Future<List<Station>> searchStations({String? query, String? tag}) async {
    return popular;
  }

  @override
  Future<List<Station>> getFavorites() async {
    return favorites;
  }

  @override
  Future<bool> isFavorite(String stationuuid) async {
    return favorites.any((s) => s.stationuuid == stationuuid);
  }

  @override
  Future<void> addFavorite(Station station) async {
    if (!favorites.any((s) => s.stationuuid == station.stationuuid)) {
      favorites.add(station);
    }
  }

  @override
  Future<void> removeFavorite(String stationuuid) async {
    favorites.removeWhere((s) => s.stationuuid == stationuuid);
  }

  @override
  Future<List<Station>> getHistory() async {
    return history;
  }

  @override
  Future<void> addHistory(Station station) async {
    history.removeWhere((s) => s.stationuuid == station.stationuuid);
    history.insert(0, station);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Station Model Tests', () {
    test('Should parse Station from JSON correctly', () {
      final json = {
        'stationuuid': 'abc-123',
        'name': 'Jazz FM',
        'url': 'http://stream.jazz.fm',
        'url_resolved': 'https://stream.jazz.fm/resolved',
        'homepage': 'https://jazz.fm',
        'favicon': 'https://jazz.fm/logo.png',
        'tags': 'jazz, smooth, instrumental',
        'country': 'United Kingdom',
        'countrycode': 'GB',
        'state': 'London',
        'language': 'English',
        'codec': 'AAC',
        'bitrate': 128,
        'votes': 1500,
        'clickcount': 25000,
      };

      final station = Station.fromJson(json);

      expect(station.stationuuid, 'abc-123');
      expect(station.name, 'Jazz FM');
      expect(station.urlResolved, 'https://stream.jazz.fm/resolved');
      expect(station.tagList, ['jazz', 'smooth', 'instrumental']);
      expect(station.bitrate, 128);
    });

    test('Should handle null/missing values in JSON fallback', () {
      final json = {
        'stationuuid': 'xyz-987',
        'name': null,
        'url': 'http://stream.url',
      };

      final station = Station.fromJson(json);

      expect(station.stationuuid, 'xyz-987');
      expect(station.name, 'Unknown Station');
      expect(station.urlResolved, 'http://stream.url');
      expect(station.tagList, isEmpty);
      expect(station.bitrate, 0);
    });
  });

  group('Favorites Provider Tests', () {
    test('Should toggle favorite station reactively', () async {
      final station = Station(
        stationuuid: 'fav-1',
        name: 'Test Radio',
        url: 'http://test.url',
        urlResolved: 'http://test.url',
        homepage: '',
        favicon: '',
        tags: '',
        country: '',
        countrycode: '',
        state: '',
        language: '',
        codec: 'MP3',
        bitrate: 128,
        votes: 10,
        clickcount: 5,
      );

      final mockRepo = MockStationRepository();
      locator.registerSingleton<StationRepository>(mockRepo);

      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        locator.unregister<StationRepository>();
      });

      final notifier = container.read(favoritesProvider.notifier);

      // Wait for future microtask loading favorites
      await Future.delayed(Duration.zero);
      while (container.read(favoritesProvider).isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(notifier.isFavorite(station.stationuuid), isFalse);

      await notifier.toggleFavorite(station);
      expect(notifier.isFavorite(station.stationuuid), isTrue);

      await notifier.toggleFavorite(station);
      expect(notifier.isFavorite(station.stationuuid), isFalse);
    });
  });

  group('Playback Provider Basic Tests', () {
    test('Should initialize with default volume', () async {
      final mockRepo = MockStationRepository();
      locator.registerSingleton<StationRepository>(mockRepo);

      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        locator.unregister<StationRepository>();
      });

      final notifier = container.read(playbackProvider.notifier);

      await Future.delayed(Duration.zero);

      // Default volume is 1.0 in test environments
      expect(container.read(playbackProvider).volume, 1.0);
      expect(container.read(playbackProvider).isMuted, isFalse);

      notifier.setVolume(0.5);
      expect(container.read(playbackProvider).volume, 0.5);
    });

    test('Should set and clear sleep timer state correctly', () async {
      final mockRepo = MockStationRepository();
      locator.registerSingleton<StationRepository>(mockRepo);

      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        locator.unregister<StationRepository>();
      });

      final notifier = container.read(playbackProvider.notifier);

      await Future.delayed(Duration.zero);

      expect(container.read(playbackProvider).isSleepTimerActive, isFalse);

      notifier.startSleepTimer(const Duration(minutes: 10));
      expect(container.read(playbackProvider).isSleepTimerActive, isTrue);
      expect(container.read(playbackProvider).sleepTimeLeftSeconds, 600);

      notifier.cancelSleepTimer();
      expect(container.read(playbackProvider).isSleepTimerActive, isFalse);
    });
  });

  group('Browser Provider Basic Tests', () {
    test('Should initialize data and popular stations', () async {
      final mockRepo = MockStationRepository();
      final station = Station(
        stationuuid: 'pop-1',
        name: 'Popular Radio',
        url: 'http://pop.url',
        urlResolved: 'http://pop.url',
        homepage: '',
        favicon: '',
        tags: '',
        country: '',
        countrycode: '',
        state: '',
        language: '',
        codec: 'MP3',
        bitrate: 128,
        votes: 10,
        clickcount: 5,
      );
      mockRepo.popular = [station];
      locator.registerSingleton<StationRepository>(mockRepo);

      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
        locator.unregister<StationRepository>();
      });

      int elapsed = 0;
      while (!container.read(browserProvider).isInitialized && elapsed < 1000) {
        await Future.delayed(const Duration(milliseconds: 10));
        elapsed += 10;
      }

      expect(container.read(browserProvider).isInitialized, isTrue);
      expect(container.read(browserProvider).stations.length, 1);
      expect(
        container.read(browserProvider).stations.first.name,
        'Popular Radio',
      );
    });
  });
}
