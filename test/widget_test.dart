import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_radio_tuner/models/station_model.dart';
import 'package:flutter_radio_tuner/providers/favorites_provider.dart';
import 'package:flutter_radio_tuner/providers/radio_provider.dart';
import 'package:flutter_radio_tuner/core/repositories/station_repository.dart';

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
      final provider = FavoritesProvider(mockRepo);

      while (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(provider.isFavorite(station.stationuuid), isFalse);

      await provider.toggleFavorite(station);
      expect(provider.isFavorite(station.stationuuid), isTrue);

      await provider.toggleFavorite(station);
      expect(provider.isFavorite(station.stationuuid), isFalse);
    });
  });

  group('Radio Provider Basic Tests', () {
    test('Should initialize with default volume', () async {
      final mockRepo = MockStationRepository();
      final provider = RadioProvider(mockRepo);

      while (provider.isLoadingData) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Default volume is 1.0 as synced from the player state
      expect(provider.volume, 1.0);
      expect(provider.isMuted, isFalse);

      provider.setVolume(0.5);
      expect(provider.volume, 0.5);
    });

    test('Should set and clear sleep timer state correctly', () async {
      final mockRepo = MockStationRepository();
      final provider = RadioProvider(mockRepo);

      while (provider.isLoadingData) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(provider.isSleepTimerActive, isFalse);

      provider.startSleepTimer(const Duration(minutes: 10));
      expect(provider.isSleepTimerActive, isTrue);
      expect(provider.sleepTimeLeftSeconds, 600);

      provider.cancelSleepTimer();
      expect(provider.isSleepTimerActive, isFalse);
    });
  });
}
