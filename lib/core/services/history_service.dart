import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/station_model.dart';

/// Interface for the playback history service.
/// Declares methods to retrieve, add, and clear recently played stations.
abstract class HistoryService {
  Future<List<Station>> getHistory();
  Future<void> addHistory(Station station);
  Future<void> clearHistory();
}

/// SharedPreferences-backed implementation of [HistoryService]
/// for persistent storage of user's recently played radio stations.
class SharedPreferencesHistoryService implements HistoryService {
  static const String _historyKey = 'played_history_stations';
  static const int _maxHistoryCount = 15;

  /// Get the list of recently played stations.
  @override
  Future<List<Station>> getHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? historyJson = prefs.getStringList(_historyKey);

    if (historyJson == null) return [];

    return historyJson
        .map((jsonStr) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(jsonStr);
            return Station.fromJson(decoded);
          } catch (_) {
            return null;
          }
        })
        .whereType<Station>()
        .toList();
  }

  /// Add a station to playback history, moving it to the top or adding it.
  @override
  Future<void> addHistory(Station station) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // Remove if already in history to move to top
    history.removeWhere((s) => s.stationuuid == station.stationuuid);

    // Insert at index 0 (most recent)
    history.insert(0, station);

    // Limit the history count
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }

    final listJson = history.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_historyKey, listJson);
  }

  /// Clear the recently played history.
  @override
  Future<void> clearHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
