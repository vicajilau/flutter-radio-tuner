import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/di/di_providers.dart';
import '../models/station_model.dart';
import '../core/repositories/station_repository.dart';

/// Immutable state class for the radio player and browser data.
class RadioState {
  final Station? currentStation;
  final bool isPlaying;
  final bool isBuffering;
  final double volume;
  final double previousVolume;
  final String? errorMessage;
  final List<Station> stations;
  final List<Station> popularStations;
  final List<Station> historyStations;
  final List<String> tags;
  final bool isInitialized;
  final bool isLoadingData;
  final String selectedTag;
  final String searchQuery;
  final int sleepTimeLeftSeconds;
  final String? currentTrackTitle; // ICY track title (e.g. song/artist)

  RadioState({
    this.currentStation,
    this.isPlaying = false,
    this.isBuffering = false,
    this.volume = 0.8,
    this.previousVolume = 0.8,
    this.errorMessage,
    this.stations = const [],
    this.popularStations = const [],
    this.historyStations = const [],
    this.tags = const [],
    this.isInitialized = false,
    this.isLoadingData = false,
    this.selectedTag = '',
    this.searchQuery = '',
    this.sleepTimeLeftSeconds = 0,
    this.currentTrackTitle,
  });

  bool get isMuted => volume == 0.0;
  bool get isSleepTimerActive => sleepTimeLeftSeconds > 0;
  String get sleepTimeFormatted {
    if (sleepTimeLeftSeconds <= 0) return '';
    final int minutes = sleepTimeLeftSeconds ~/ 60;
    final int seconds = sleepTimeLeftSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RadioState copyWith({
    Station? Function()? currentStation,
    bool? isPlaying,
    bool? isBuffering,
    double? volume,
    double? previousVolume,
    String? Function()? errorMessage,
    List<Station>? stations,
    List<Station>? popularStations,
    List<Station>? historyStations,
    List<String>? tags,
    bool? isInitialized,
    bool? isLoadingData,
    String? selectedTag,
    String? searchQuery,
    int? sleepTimeLeftSeconds,
    String? Function()? currentTrackTitle,
  }) {
    return RadioState(
      currentStation: currentStation != null
          ? currentStation()
          : this.currentStation,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      previousVolume: previousVolume ?? this.previousVolume,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      stations: stations ?? this.stations,
      popularStations: popularStations ?? this.popularStations,
      historyStations: historyStations ?? this.historyStations,
      tags: tags ?? this.tags,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoadingData: isLoadingData ?? this.isLoadingData,
      selectedTag: selectedTag ?? this.selectedTag,
      searchQuery: searchQuery ?? this.searchQuery,
      sleepTimeLeftSeconds: sleepTimeLeftSeconds ?? this.sleepTimeLeftSeconds,
      currentTrackTitle: currentTrackTitle != null
          ? currentTrackTitle()
          : this.currentTrackTitle,
    );
  }
}

/// Notifier managing playback state, sleep timers, search filters, and recent history.
class RadioNotifier extends Notifier<RadioState> {
  final AudioPlayer _player = AudioPlayer();
  late final StationRepository _repository;

  // Timers and Subscriptions
  Timer? _sleepTimer;
  Timer? _countdownTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasPlayingBeforeDisconnect = false;

  AudioPlayer get player => _player;

  @override
  RadioState build() {
    _repository = ref.watch(stationRepositoryProvider);

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _sleepTimer?.cancel();
      _countdownTimer?.cancel();
      _player.dispose();
    });

    Future.microtask(() {
      _initPlayerListeners();
      _initConnectivityListener();
      _initVolumeController();
      _initData();
    });

    return RadioState();
  }

  void _initPlayerListeners() {
    _player.playerStateStream.listen(
      (playerState) {
        final isPlaying = playerState.playing;
        final isBuffering =
            playerState.processingState == ProcessingState.buffering ||
            playerState.processingState == ProcessingState.loading;

        state = state.copyWith(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
          errorMessage: playerState.processingState == ProcessingState.completed
              ? () => null
              : null,
        );

        if (playerState.processingState == ProcessingState.completed) {
          state = state.copyWith(isPlaying: false);
        }
      },
      onError: (Object e) {
        developer.log('Player Stream Error: $e');
        state = state.copyWith(
          errorMessage: () => 'An error occurred during playback.',
          isBuffering: false,
          isPlaying: false,
        );
      },
    );

    // Subscribe to live metadata stream (ICY metadata)
    _player.icyMetadataStream.listen(
      (icyMetadata) {
        final title = icyMetadata?.info?.title;
        developer.log('Received ICY Metadata: $title');
        state = state.copyWith(currentTrackTitle: () => title);
      },
      onError: (Object e) {
        developer.log('ICY Metadata stream error: $e');
      },
    );

    _player.setVolume(state.volume);
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final hasConnection = !results.contains(ConnectivityResult.none);

        if (!hasConnection) {
          if (state.isPlaying) {
            developer.log('Internet connection lost. Pausing playback.');
            _wasPlayingBeforeDisconnect = true;
            await _player.pause();
            state = state.copyWith(
              isPlaying: false,
              errorMessage: () => 'No internet connection. Playback paused.',
            );
          }
        } else {
          if (_wasPlayingBeforeDisconnect && state.currentStation != null) {
            developer.log('Internet connection restored. Re-buffering stream.');
            _wasPlayingBeforeDisconnect = false;
            state = state.copyWith(isBuffering: true, errorMessage: () => null);
            try {
              await playStation(state.currentStation!);
            } catch (e) {
              developer.log('Auto-reconnection failed: $e');
            }
          }
        }
      },
      onError: (Object e) {
        developer.log('Connectivity stream error: $e');
      },
    );
  }

  Future<void> _initData() async {
    state = state.copyWith(isLoadingData: true, errorMessage: () => null);

    try {
      await _repository.initialize();
      final popular = await _repository.getPopularStations();

      List<String> tagsList = [];
      try {
        tagsList = await _repository.getPopularTags();
      } catch (e) {
        developer.log('Error fetching tags: $e');
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

      await loadHistory();

      state = state.copyWith(
        popularStations: popular,
        tags: tagsList,
        stations: List.from(popular),
        isInitialized: true,
        isLoadingData: false,
      );
    } catch (e) {
      developer.log('Initialization error: $e');
      state = state.copyWith(
        errorMessage: () =>
            'Failed to load initial radio data. Please check your connection.',
        stations: [],
        isLoadingData: false,
      );
    }
  }

  Future<void> retryInitialization() async {
    await _initData();
  }

  // --- API / Repository Methods ---

  Future<void> fetchPopularStations() async {
    try {
      final popular = await _repository.getPopularStations();
      state = state.copyWith(popularStations: popular);
    } catch (e) {
      developer.log('Error fetching popular stations: $e');
    }
  }

  Future<void> fetchTags() async {
    try {
      final tagsList = await _repository.getPopularTags();
      state = state.copyWith(tags: tagsList);
    } catch (e) {
      developer.log('Error fetching tags: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      final history = await _repository.getHistory();
      state = state.copyWith(historyStations: history);
    } catch (e) {
      developer.log('Error fetching history: $e');
    }
  }

  /// Search and filter stations using query and selected tag
  Future<void> search({String? query, String? tag}) async {
    state = state.copyWith(isLoadingData: true);

    String currentQuery = state.searchQuery;
    String currentTag = state.selectedTag;

    if (query != null) currentQuery = query;
    if (tag != null) {
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
      developer.log('Search error: $e');
      state = state.copyWith(
        errorMessage: () => 'Search failed. Please try again.',
        stations: [],
        isLoadingData: false,
      );
    }
  }

  /// Clear active filters and search queries
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

  // --- Audio Control Methods ---

  /// Play a selected radio station.
  Future<void> playStation(Station station) async {
    if (state.currentStation?.stationuuid == station.stationuuid &&
        _player.processingState == ProcessingState.ready) {
      togglePlay();
      return;
    }

    // Keep player internal volume matching system volume
    await _player.setVolume(state.volume);

    state = state.copyWith(
      currentStation: () => station,
      isBuffering: true,
      errorMessage: () => null,
      currentTrackTitle: () => null, // Reset track metadata
    );

    // Add to history list reactive state and DB
    _repository.addHistory(station);
    loadHistory(); // Reload history

    try {
      final session = await AudioSession.instance;
      await session.setActive(true);

      await _player.setVolume(state.volume);

      final String streamUrl = station.urlResolved.isNotEmpty
          ? station.urlResolved
          : station.url;

      developer.log('Loading live radio stream: $streamUrl');

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id: station.stationuuid,
            album: station.country.isNotEmpty ? station.country : 'Radio Tuner',
            title: station.name,
            artUri: station.favicon.isNotEmpty
                ? Uri.tryParse(station.favicon)
                : null,
          ),
        ),
      );

      _player.play();
    } catch (e) {
      developer.log('Error playing stream: $e');
      state = state.copyWith(
        errorMessage: () =>
            'Unable to play this station. The stream may be offline.',
        isBuffering: false,
        isPlaying: false,
      );
      await _player.stop();
    }
  }

  /// Toggle between play and pause.
  void togglePlay() {
    if (state.currentStation == null) return;

    if (state.isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  /// Stop playback, cancel sleep timers, and clear active station
  Future<void> stopRadio() async {
    cancelSleepTimer();
    state = state.copyWith(
      isBuffering: false,
      isPlaying: false,
      currentStation: () => null,
      currentTrackTitle: () => null,
    );
    await _player.stop();
  }

  // --- Volume Control Methods ---

  Future<void> _initVolumeController() async {
    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      state = state.copyWith(volume: 1.0);
      return;
    }

    try {
      await FlutterVolumeController.updateShowSystemUI(false);

      final double? systemVolume = await FlutterVolumeController.getVolume();
      if (systemVolume != null) {
        state = state.copyWith(volume: systemVolume);
        _player.setVolume(systemVolume);
      }

      FlutterVolumeController.addListener((vol) {
        state = state.copyWith(volume: vol);
        _player.setVolume(vol);
      });
    } catch (e) {
      developer.log('Failed to initialize volume controller: $e');
    }
  }

  void setVolume(double val) {
    final volume = val.clamp(0.0, 1.0);
    state = state.copyWith(volume: volume);

    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      try {
        FlutterVolumeController.setVolume(volume);
      } catch (e) {
        developer.log('Failed to set system volume: $e');
      }
    }

    _player.setVolume(volume);
  }

  /// Toggle mute state.
  void toggleMute() {
    if (state.isMuted) {
      setVolume(state.previousVolume > 0.0 ? state.previousVolume : 0.8);
    } else {
      state = state.copyWith(previousVolume: state.volume);
      setVolume(0.0);
    }
  }

  // --- Sleep Timer Methods ---

  /// Start a sleep timer to pause playback after a duration.
  void startSleepTimer(Duration duration) {
    cancelSleepTimer();

    state = state.copyWith(sleepTimeLeftSeconds: duration.inSeconds);

    // Countdown tick timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.sleepTimeLeftSeconds > 0) {
        state = state.copyWith(
          sleepTimeLeftSeconds: state.sleepTimeLeftSeconds - 1,
        );
      } else {
        timer.cancel();
      }
    });

    // Expiry timer
    _sleepTimer = Timer(duration, () async {
      developer.log('Sleep timer triggered. Stopping playback.');

      // Fade out player volume
      const int steps = 10;
      final double initialPlayerVolume = _player.volume;
      final double stepVolume = initialPlayerVolume / steps;

      for (int i = 1; i <= steps; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        await _player.setVolume(
          (initialPlayerVolume - (stepVolume * i)).clamp(0.0, 1.0),
        );
      }

      _player.pause();

      // Restore volume for next time
      await _player.setVolume(initialPlayerVolume);
      cancelSleepTimer();
    });
  }

  /// Cancel any active sleep timer.
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(sleepTimeLeftSeconds: 0);
  }
}

/// Global provider for the radio state.
final radioProvider = NotifierProvider<RadioNotifier, RadioState>(() {
  return RadioNotifier();
});
