import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../models/station_model.dart';
import 'hive_service.dart';

/// Interface for the API service.
/// Declares operations to communicate with the Radio Browser API,
/// including server initialization, station search, and fetching popular tags.
abstract class ApiService {
  Future<void> initialize();
  Future<List<Station>> getTopStations({int limit, bool forceRefresh});
  Future<List<Station>> searchStations({
    String? name,
    String? country,
    String? tag,
    String? language,
    int limit,
  });
  Future<List<String>> getTopTags({int limit, bool forceRefresh});
  Future<List<Map<String, String>>> getTopCountries({int limit});
  Future<List<Station>> getCachedTopStations({int limit});
  Future<List<String>> getCachedTopTags({int limit});
}

/// Concrete implementation of [ApiService] using the Dio HTTP client.
/// Dynamically resolves the best active server from the Radio Browser network.
/// Implements lightweight memory caching for popular stations, tags, and countries.
class DioApiService implements ApiService {
  final Dio _dio;
  final HiveService _hiveService;

  List<String> _availableServers = [
    'de1.api.radio-browser.info',
    'fr1.api.radio-browser.info',
    'nl1.api.radio-browser.info',
    'at1.api.radio-browser.info',
  ];
  int _currentServerIndex = 0;

  String get _baseUrl => 'https://${_availableServers[_currentServerIndex]}';

  // Cache configuration
  static const Duration _cacheDuration = Duration(minutes: 5);
  final Map<String, _CacheEntry<List<Station>>> _stationsCache = {};
  final Map<String, _CacheEntry<List<String>>> _tagsCache = {};
  final Map<String, _CacheEntry<List<Map<String, String>>>> _countriesCache =
      {};

  Future<void> _writeToPersistentCache(String key, dynamic data) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      await _hiveService.putCacheValue(key, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Failed to write to persistent cache: $e');
    }
  }

  Future<dynamic> _readFromPersistentCache(String key, Duration maxAge) async {
    try {
      final String? cachedStr = _hiveService.getCacheValue(key);
      if (cachedStr == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(cachedStr);
      final String? timestampStr = decoded['timestamp'];
      if (timestampStr == null) return null;

      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null) return null;

      if (DateTime.now().difference(timestamp) > maxAge) {
        return null; // Expired
      }
      return decoded['data'];
    } catch (e) {
      debugPrint('Failed to read from persistent cache: $e');
      return null;
    }
  }

  DioApiService(this._hiveService)
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent': 'FlutterRadioTuner/1.0.0 (com.labhouse.radiotuner)',
          },
        ),
      );

  /// Initializes the service by resolving the best active API server base URL.
  @override
  Future<void> initialize() async {
    try {
      final response = await _dio.get(
        'https://all.api.radio-browser.info/json/servers',
      );
      if (response.statusCode == 200 &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        final List servers = response.data;
        final List<String> resolved = [];
        for (var server in servers) {
          if (server['name'] != null) {
            resolved.add(server['name'].toString());
          }
        }
        if (resolved.isNotEmpty) {
          resolved.shuffle();
          _availableServers = resolved;
          _currentServerIndex = 0;
          debugPrint(
            'Resolved ${resolved.length} active Radio Browser API servers. Starting with: $_baseUrl',
          );
          return;
        }
      }
    } catch (e) {
      debugPrint(
        'Failed to resolve active servers list, falling back to default mirrors. Error: $e',
      );
    }
  }

  /// Runs an API request and automatically falls back to a different mirror if it fails.
  Future<T> _requestWithFallback<T>(Future<T> Function() requestFn) async {
    int attempts = 0;
    final int maxAttempts = _availableServers.length.clamp(1, 5);
    dynamic lastError;

    while (attempts < maxAttempts) {
      try {
        return await requestFn();
      } catch (e) {
        lastError = e;
        attempts++;
        debugPrint(
          'Request failed using $_baseUrl. Attempt $attempts of $maxAttempts. Error: $e',
        );
        if (attempts >= maxAttempts) {
          break;
        }
        // Rotate to the next available server
        _currentServerIndex =
            (_currentServerIndex + 1) % _availableServers.length;
        debugPrint('Falling back to next server: $_baseUrl');
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw Exception('All API servers failed.');
  }

  /// Get top clicked/popular radio stations.
  @override
  Future<List<Station>> getTopStations({
    int limit = 40,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'top_stations_$limit';
    if (!forceRefresh) {
      if (_stationsCache.containsKey(cacheKey)) {
        final entry = _stationsCache[cacheKey]!;
        if (!entry.isExpired(_cacheDuration)) {
          debugPrint('Returning cached top stations for limit $limit');
          return entry.data;
        }
      }

      final persistentCachedData = await _readFromPersistentCache(
        cacheKey,
        _cacheDuration,
      );
      if (persistentCachedData != null && persistentCachedData is List) {
        debugPrint('Returning persistent cached top stations for limit $limit');
        try {
          final list = (persistentCachedData)
              .map((json) => Station.fromJson(json as Map<String, dynamic>))
              .toList();
          _stationsCache[cacheKey] = _CacheEntry(list);
          return list;
        } catch (e) {
          debugPrint('Failed to parse persistent cached top stations: $e');
        }
      }
    }

    try {
      final stations = await _requestWithFallback(() async {
        final response = await _dio.get(
          '$_baseUrl/json/stations/topclick/$limit',
        );
        if (response.statusCode == 200 && response.data is List) {
          final List list = response.data;
          return list.map((json) => Station.fromJson(json)).toList();
        }
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      });

      _stationsCache[cacheKey] = _CacheEntry(stations);
      await _writeToPersistentCache(
        cacheKey,
        stations.map((s) => s.toJson()).toList(),
      );
      return stations;
    } catch (e) {
      debugPrint(
        'Network request failed for top stations, attempting expired cache fallback: $e',
      );
      final fallbackData = await _readFromPersistentCache(
        cacheKey,
        const Duration(days: 30),
      );
      if (fallbackData != null && fallbackData is List) {
        try {
          final list = (fallbackData)
              .map((json) => Station.fromJson(json as Map<String, dynamic>))
              .toList();
          return list;
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Search radio stations based on custom parameters.
  @override
  Future<List<Station>> searchStations({
    String? name,
    String? country,
    String? tag,
    String? language,
    int limit = 50,
  }) async {
    // Search is dynamic, so we do not cache general searches to ensure real-time results.
    return _requestWithFallback(() async {
      final Map<String, dynamic> queryParameters = {
        'limit': limit,
        'hidebroken': 'true',
        'order': 'clickcount',
        'reverse': 'true',
      };

      if (name != null && name.trim().isNotEmpty) {
        queryParameters['name'] = name.trim();
      }
      if (country != null && country.trim().isNotEmpty) {
        queryParameters['country'] = country.trim();
      }
      if (tag != null && tag.trim().isNotEmpty) {
        queryParameters['tag'] = tag.trim();
      }
      if (language != null && language.trim().isNotEmpty) {
        queryParameters['language'] = language.trim();
      }

      final response = await _dio.get(
        '$_baseUrl/json/stations/search',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((json) => Station.fromJson(json)).toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    });
  }

  /// Fetch top tags/genres by station count.
  @override
  Future<List<String>> getTopTags({
    int limit = 15,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'top_tags_$limit';
    if (!forceRefresh) {
      if (_tagsCache.containsKey(cacheKey)) {
        final entry = _tagsCache[cacheKey]!;
        if (!entry.isExpired(_cacheDuration)) {
          debugPrint('Returning cached top tags for limit $limit');
          return entry.data;
        }
      }

      final persistentCachedData = await _readFromPersistentCache(
        cacheKey,
        _cacheDuration,
      );
      if (persistentCachedData != null && persistentCachedData is List) {
        debugPrint('Returning persistent cached top tags for limit $limit');
        try {
          final list = List<String>.from(persistentCachedData);
          _tagsCache[cacheKey] = _CacheEntry(list);
          return list;
        } catch (e) {
          debugPrint('Failed to parse persistent cached top tags: $e');
        }
      }
    }

    try {
      final tags = await _requestWithFallback(() async {
        final response = await _dio.get(
          '$_baseUrl/json/tags',
          queryParameters: {
            'limit': limit,
            'order': 'stationcount',
            'reverse': 'true',
            'hidebroken': 'true',
          },
        );

        if (response.statusCode == 200 && response.data is List) {
          final List list = response.data;
          return list
              .map((item) => item['name']?.toString() ?? '')
              .where((name) => name.isNotEmpty && name.length > 2)
              .toList();
        }
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      });

      _tagsCache[cacheKey] = _CacheEntry(tags);
      await _writeToPersistentCache(cacheKey, tags);
      return tags;
    } catch (e) {
      debugPrint('Error fetching tags, attempting expired cache fallback: $e');
      final fallbackData = await _readFromPersistentCache(
        cacheKey,
        const Duration(days: 30),
      );
      if (fallbackData != null && fallbackData is List) {
        try {
          return List<String>.from(fallbackData);
        } catch (_) {}
      }
      return [
        'Pop',
        'Rock',
        'Jazz',
        'Classical',
        'News',
        'Dance',
        'Metal',
        'Lounge',
      ];
    }
  }

  /// Fetch top countries by station count.
  @override
  Future<List<Map<String, String>>> getTopCountries({int limit = 15}) async {
    final cacheKey = 'top_countries_$limit';
    if (_countriesCache.containsKey(cacheKey)) {
      final entry = _countriesCache[cacheKey]!;
      if (!entry.isExpired(_cacheDuration)) {
        debugPrint('Returning cached top countries for limit $limit');
        return entry.data;
      }
    }

    final persistentCachedData = await _readFromPersistentCache(
      cacheKey,
      _cacheDuration,
    );
    if (persistentCachedData != null && persistentCachedData is List) {
      debugPrint('Returning persistent cached top countries for limit $limit');
      try {
        final list = (persistentCachedData)
            .map<Map<String, String>>(
              (item) => Map<String, String>.from(item as Map),
            )
            .toList();
        _countriesCache[cacheKey] = _CacheEntry(list);
        return list;
      } catch (e) {
        debugPrint('Failed to parse persistent cached top countries: $e');
      }
    }

    try {
      final countries = await _requestWithFallback(() async {
        final response = await _dio.get(
          '$_baseUrl/json/countries',
          queryParameters: {
            'limit': limit,
            'order': 'stationcount',
            'reverse': 'true',
          },
        );

        if (response.statusCode == 200 && response.data is List) {
          final List list = response.data;
          return list
              .map<Map<String, String>>(
                (item) => {
                  'name': item['name']?.toString() ?? '',
                  'code': item['iso_3166_1']?.toString() ?? '',
                },
              )
              .where((c) => c['name']!.isNotEmpty)
              .toList();
        }
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      });

      _countriesCache[cacheKey] = _CacheEntry(countries);
      await _writeToPersistentCache(cacheKey, countries);
      return countries;
    } catch (e) {
      debugPrint(
        'Error fetching countries, attempting expired cache fallback: $e',
      );
      final fallbackData = await _readFromPersistentCache(
        cacheKey,
        const Duration(days: 30),
      );
      if (fallbackData != null && fallbackData is List) {
        try {
          return (fallbackData)
              .map<Map<String, String>>(
                (item) => Map<String, String>.from(item as Map),
              )
              .toList();
        } catch (_) {}
      }
      return [];
    }
  }

  @override
  Future<List<Station>> getCachedTopStations({int limit = 40}) async {
    final cacheKey = 'top_stations_$limit';
    final persistentCachedData = await _readFromPersistentCache(
      cacheKey,
      const Duration(days: 30),
    );
    if (persistentCachedData != null && persistentCachedData is List) {
      try {
        return (persistentCachedData)
            .map((json) => Station.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<List<String>> getCachedTopTags({int limit = 15}) async {
    final cacheKey = 'top_tags_$limit';
    final persistentCachedData = await _readFromPersistentCache(
      cacheKey,
      const Duration(days: 30),
    );
    if (persistentCachedData != null && persistentCachedData is List) {
      try {
        return List<String>.from(persistentCachedData);
      } catch (_) {}
    }
    return [];
  }
}

/// Helper class representing a cache entry with a timestamp.
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool isExpired(Duration duration) {
    return DateTime.now().difference(timestamp) > duration;
  }
}
