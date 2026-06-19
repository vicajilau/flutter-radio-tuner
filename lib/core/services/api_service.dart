import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../models/station_model.dart';

abstract class ApiService {
  Future<void> initialize();
  Future<List<Station>> getTopStations({int limit});
  Future<List<Station>> searchStations({
    String? name,
    String? country,
    String? tag,
    String? language,
    int limit,
  });
  Future<List<String>> getTopTags({int limit});
  Future<List<Map<String, String>>> getTopCountries({int limit});
}

class DioApiService implements ApiService {
  final Dio _dio;
  String _baseUrl = 'https://de1.api.radio-browser.info'; // Default fallback

  DioApiService()
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
        // Find a server that is online and has a valid name
        for (var server in servers) {
          if (server['name'] != null) {
            _baseUrl = 'https://${server['name']}';
            developer.log(
              'Resolved active Radio Browser API server: $_baseUrl',
            );
            return;
          }
        }
      }
    } catch (e) {
      developer.log(
        'Failed to resolve active server, falling back to $_baseUrl. Error: $e',
      );
    }
  }

  /// Get top clicked/popular radio stations.
  @override
  Future<List<Station>> getTopStations({int limit = 40}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/json/stations/topclick/$limit',
      );
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((json) => Station.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      developer.log('Error fetching top stations: $e');
      throw Exception(
        'Failed to fetch popular stations. Please check your internet connection.',
      );
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
    try {
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
      return [];
    } catch (e) {
      developer.log('Error searching stations: $e');
      throw Exception(
        'Failed to search stations. Please check your internet connection.',
      );
    }
  }

  /// Fetch top tags/genres by station count.
  @override
  Future<List<String>> getTopTags({int limit = 15}) async {
    try {
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
      return [];
    } catch (e) {
      developer.log('Error fetching tags: $e');
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
    try {
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
      return [];
    } catch (e) {
      developer.log('Error fetching countries: $e');
      return [];
    }
  }
}
