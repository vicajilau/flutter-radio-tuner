import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/di/service_locator.dart';
import '../models/station_model.dart';
import '../core/repositories/station_repository.dart';

/// ============================================================================
/// BROWSER PROVIDER
/// ============================================================================
///
/// This provider is responsible exclusively for searching, browsing, caching,
/// and displaying radio stations from the repository (Single Responsibility Principle).
///
/// **Key Responsibilities:**
/// 1. Queries the [StationRepository] for popular stations, category tags, and countries.
/// 2. Manages search queries and tag filtering logic in the exploration section.
/// 3. Maintains the loaded list of historical stations locally logged.
/// 4. Exposes state flags such as initialization status, active loadings, or API error messages.
///
/// **Decoupling Rationale:**
/// Keeps all search query state, text changes, loading flags, and lists isolated.
/// This prevents keystroke debounces or country category filter changes in the UI
/// from triggering rebuilds of the active audio player screen or player controls.
/// ============================================================================

/// Immutable state containing loaded list data and active search filters.
class BrowserState {
  /// The current list of search results or recommended popular stations.
  final List<Station> stations;

  /// Cached list of top popular stations resolved at startup.
  final List<Station> popularStations;

  /// List of recently played stations fetched from local storage.
  final List<Station> historyStations;

  /// Loaded list of popular category tags (e.g. Pop, Rock, Jazz).
  final List<String> tags;

  /// True if initial station discovery, countries, and tags are loaded successfully.
  final bool isInitialized;

  /// True if an active API query or filter is fetching data in the background.
  final bool isLoadingData;

  /// The active category tag filter. Empty string if no tag is selected.
  final String selectedTag;

  /// The active text search query. Empty string if no text is queried.
  final String searchQuery;

  /// Error message string in case the API search or tag listing fails.
  final String? errorMessage;

  BrowserState({
    this.stations = const [],
    this.popularStations = const [],
    this.historyStations = const [],
    this.tags = const [],
    this.isInitialized = false,
    this.isLoadingData = false,
    this.selectedTag = '',
    this.searchQuery = '',
    this.errorMessage,
  });

  /// Create a copy of the state with modified fields.
  /// Nullable [errorMessage] utilizes a generator function `Value? Function()?`
  /// to support explicitly resetting the error message back to null.
  BrowserState copyWith({
    List<Station>? stations,
    List<Station>? popularStations,
    List<Station>? historyStations,
    List<String>? tags,
    bool? isInitialized,
    bool? isLoadingData,
    String? selectedTag,
    String? searchQuery,
    String? Function()? errorMessage,
  }) {
    return BrowserState(
      stations: stations ?? this.stations,
      popularStations: popularStations ?? this.popularStations,
      historyStations: historyStations ?? this.historyStations,
      tags: tags ?? this.tags,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoadingData: isLoadingData ?? this.isLoadingData,
      selectedTag: selectedTag ?? this.selectedTag,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

/// Notifier managing station searches, category listing, caching, and history lists.
class BrowserNotifier extends Notifier<BrowserState> {
  late final StationRepository _repository;

  @override
  BrowserState build() {
    // Resolve the station repository singleton via GetIt locator
    _repository = locator<StationRepository>();

    // Defer initial data load so it runs after the provider is fully built
    Future.microtask(() {
      _initData();
    });

    return BrowserState();
  }

  /// Initial setup fetching popular stations, tags, and local history.
  Future<void> _initData() async {
    state = state.copyWith(isLoadingData: true, errorMessage: () => null);

    try {
      // Connect to the API server and establish connectivity checks
      await _repository.initialize();

      // Fetch popular stations (will use Dio memory caching internally)
      final popular = await _repository.getPopularStations();

      // Fetch popular tags (with static fallback in case of server failure)
      List<String> tagsList = [];
      try {
        tagsList = await _repository.getPopularTags();
      } catch (e) {
        debugPrint('Error fetching tags: $e');
        tagsList = [
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

      // Load local history log
      await loadHistory();

      state = state.copyWith(
        popularStations: popular,
        tags: tagsList,
        stations: List.from(popular),
        isInitialized: true,
        isLoadingData: false,
      );
    } catch (e) {
      debugPrint('Initialization error: $e');
      state = state.copyWith(
        errorMessage: () =>
            'Failed to load initial radio data. Please check your connection.',
        stations: [],
        isLoadingData: false,
      );
    }
  }

  /// Retry initialization if the startup API query fails.
  Future<void> retryInitialization() async {
    await _initData();
  }

  /// Fetch popular stations from the API server.
  Future<void> fetchPopularStations() async {
    try {
      final popular = await _repository.getPopularStations();
      state = state.copyWith(popularStations: popular);
    } catch (e) {
      debugPrint('Error fetching popular stations: $e');
    }
  }

  /// Fetch popular tags from the API server.
  Future<void> fetchTags() async {
    try {
      final tagsList = await _repository.getPopularTags();
      state = state.copyWith(tags: tagsList);
    } catch (e) {
      debugPrint('Error fetching tags: $e');
    }
  }

  /// Load recently played stations list from local disk.
  Future<void> loadHistory() async {
    try {
      final history = await _repository.getHistory();
      state = state.copyWith(historyStations: history);
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  /// Search and filter stations using query and/or selected tag.
  ///
  /// Updates search filters in the state and performs repository queries.
  /// If filters are completely empty, falls back to the popular stations list.
  Future<void> search({String? query, String? tag}) async {
    state = state.copyWith(isLoadingData: true);

    String currentQuery = state.searchQuery;
    String currentTag = state.selectedTag;

    if (query != null) {
      currentQuery = query;
    }
    if (tag != null) {
      // Toggle logic: if tag is already selected, deselect it. Otherwise select it.
      if (currentTag == tag) {
        currentTag = '';
      } else {
        currentTag = tag;
      }
    }

    state = state.copyWith(searchQuery: currentQuery, selectedTag: currentTag);

    try {
      List<Station> results = [];
      if (currentQuery.isEmpty && currentTag.isEmpty) {
        results = List.from(state.popularStations);
      } else {
        results = await _repository.searchStations(
          query: currentQuery.isNotEmpty ? currentQuery : null,
          tag: currentTag.isNotEmpty ? currentTag : null,
        );
      }
      state = state.copyWith(stations: results, isLoadingData: false);
    } catch (e) {
      debugPrint('Search error: $e');
      state = state.copyWith(
        errorMessage: () => 'Search failed. Please try again.',
        stations: [],
        isLoadingData: false,
      );
    }
  }

  /// Clear all active search terms, tag filters, and restore initial popular stations.
  Future<void> clearFilters() async {
    state = state.copyWith(
      searchQuery: '',
      selectedTag: '',
      isLoadingData: true,
    );
    try {
      state = state.copyWith(
        stations: List.from(state.popularStations),
        isLoadingData: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingData: false);
    }
  }
}

/// Global Riverpod provider exposing the station browser state and notifier controls.
final browserProvider = NotifierProvider<BrowserNotifier, BrowserState>(() {
  return BrowserNotifier();
});
