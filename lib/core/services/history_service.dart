import 'dart:convert';
import '../../models/station_model.dart';
import 'hive_service.dart';

/// Interface for the playback history service.
/// Declares methods to retrieve, add, and clear recently played stations.
abstract class HistoryService {
  Future<List<Station>> getHistory();
  Future<void> addHistory(Station station);
  Future<void> clearHistory();
}

/// Hive-backed implementation of [HistoryService]
/// for persistent storage of user's recently played radio stations.
class HiveHistoryService implements HistoryService {
  static const String _historyKey = 'history_list';
  static const int _maxHistoryCount = 15;

  final HiveService _hiveService;

  HiveHistoryService(this._hiveService);

  /// Get the list of recently played stations.
  @override
  Future<List<Station>> getHistory() async {
    final String? historyJsonStr = _hiveService.getHistoryValue(_historyKey);
    if (historyJsonStr == null) return [];

    try {
      final List decodedList = jsonDecode(historyJsonStr) as List;
      return decodedList
          .map((json) => Station.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a station to playback history, moving it to the top or adding it.
  @override
  Future<void> addHistory(Station station) async {
    final history = await getHistory();

    // Remove if already in history to move to top
    history.removeWhere((s) => s.stationuuid == station.stationuuid);

    // Insert at index 0 (most recent)
    history.insert(0, station);

    // Limit the history count
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }

    final String encoded = jsonEncode(history.map((s) => s.toJson()).toList());
    await _hiveService.putHistoryValue(_historyKey, encoded);
  }

  /// Clear the recently played history.
  @override
  Future<void> clearHistory() async {
    await _hiveService.deleteHistoryValue(_historyKey);
  }
}
