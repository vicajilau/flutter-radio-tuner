import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../../models/station_model.dart';
import '../core/repositories/station_repository.dart';

/// ChangeNotifier that manages the application state for radio playback,
/// volume level control, sleep timer scheduler, search filters, and recent history.
class RadioProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final StationRepository _repository;

  // Audio Player State
  Station? _currentStation;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _volume = 0.8;
  double _previousVolume = 0.8; // For mute/unmute
  String? _errorMessage;

  // API Data State
  List<Station> _stations = [];
  List<Station> _popularStations = [];
  List<Station> _historyStations = [];
  List<String> _tags = [];
  bool _isInitialized = false;
  bool _isLoadingData = false;
  String _selectedTag = '';
  String _searchQuery = '';

  // Sleep Timer State
  Timer? _sleepTimer;
  Timer? _countdownTimer;
  int _sleepTimeLeftSeconds = 0; // seconds left

  // Getters
  AudioPlayer get player => _player;
  Station? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  double get volume => _volume;
  bool get isMuted => _volume == 0.0;
  String? get errorMessage => _errorMessage;

  List<Station> get stations => _stations;
  List<Station> get popularStations => _popularStations;
  List<Station> get historyStations => _historyStations;
  List<String> get tags => _tags;
  bool get isInitialized => _isInitialized;
  bool get isLoadingData => _isLoadingData;
  String get selectedTag => _selectedTag;
  String get searchQuery => _searchQuery;

  bool get isSleepTimerActive => _sleepTimer != null;
  int get sleepTimeLeftSeconds => _sleepTimeLeftSeconds;
  String get sleepTimeFormatted {
    if (_sleepTimeLeftSeconds <= 0) return '';
    final int minutes = _sleepTimeLeftSeconds ~/ 60;
    final int seconds = _sleepTimeLeftSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RadioProvider(this._repository) {
    _initPlayerListeners();
    _initVolumeController();
    _initData();
  }

  void _initPlayerListeners() {
    _player.playerStateStream.listen(
      (state) {
        _isPlaying = state.playing;
        _isBuffering =
            state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;

        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        developer.log('Player Stream Error: $e');
        _errorMessage = 'An error occurred during playback.';
        _isBuffering = false;
        _isPlaying = false;
        notifyListeners();
      },
    );

    // Initialize player internal volume to match default volume
    _player.setVolume(_volume);
  }

  Future<void> _initData() async {
    _isLoadingData = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.initialize();
      _popularStations = await _repository.getPopularStations();

      try {
        _tags = await _repository.getPopularTags();
      } catch (e) {
        developer.log('Error fetching tags: $e');
        _tags = [
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
      _stations = List.from(_popularStations);
      _isInitialized = true;
    } catch (e) {
      developer.log('Initialization error: $e');
      _errorMessage =
          'Failed to load initial radio data. Please check your connection.';
      _stations = [];
    } finally {
      _isLoadingData = false;
      notifyListeners();
    }
  }

  Future<void> retryInitialization() async {
    await _initData();
  }

  // --- API Methods ---

  Future<void> fetchPopularStations() async {
    try {
      _popularStations = await _repository.getPopularStations();
    } catch (e) {
      developer.log('Error fetching popular stations: $e');
    }
  }

  Future<void> fetchTags() async {
    try {
      _tags = await _repository.getPopularTags();
    } catch (e) {
      developer.log('Error fetching tags: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      _historyStations = await _repository.getHistory();
    } catch (e) {
      developer.log('Error fetching history: $e');
    }
  }

  /// Search and filter stations using query and selected tag
  Future<void> search({String? query, String? tag}) async {
    _isLoadingData = true;
    if (query != null) _searchQuery = query;
    if (tag != null) {
      // Toggle tag selection
      if (_selectedTag == tag) {
        _selectedTag = '';
      } else {
        _selectedTag = tag;
      }
    }
    notifyListeners();

    try {
      if (_searchQuery.isEmpty && _selectedTag.isEmpty) {
        // Fallback to top clicked
        _stations = List.from(_popularStations);
      } else {
        _stations = await _repository.searchStations(
          query: _searchQuery.isNotEmpty ? _searchQuery : null,
          tag: _selectedTag.isNotEmpty ? _selectedTag : null,
        );
      }
    } catch (e) {
      developer.log('Search error: $e');
      _errorMessage = 'Search failed. Please try again.';
      _stations = [];
    } finally {
      _isLoadingData = false;
      notifyListeners();
    }
  }

  /// Clear active filters and search queries
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedTag = '';
    _isLoadingData = true;
    notifyListeners();
    try {
      _stations = List.from(_popularStations);
    } finally {
      _isLoadingData = false;
      notifyListeners();
    }
  }

  // --- Audio Control Methods ---

  /// Play a selected radio station.
  Future<void> playStation(Station station) async {
    if (_currentStation?.stationuuid == station.stationuuid &&
        _player.processingState == ProcessingState.ready) {
      togglePlay();
      return;
    }

    // Ensure player internal volume is reset to match system volume
    await _player.setVolume(_volume);

    _currentStation = station;
    _isBuffering = true;
    _errorMessage = null;
    notifyListeners();

    // Add to history list reactive state and DB
    _repository.addHistory(station);
    loadHistory(); // Reload history from SharedPreferences

    try {
      // Activate audio session explicitly for background / lockscreen registration
      final session = await AudioSession.instance;
      await session.setActive(true);

      // Keep player internal volume matching system volume
      await _player.setVolume(_volume);

      // Use url_resolved as recommended by the API documentation
      final String streamUrl = station.urlResolved.isNotEmpty
          ? station.urlResolved
          : station.url;

      developer.log('Loading live radio stream: $streamUrl');

      // Set audio source (buffers the stream)
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

      // Start playback
      _player.play();
    } catch (e) {
      developer.log('Error playing stream: $e');
      _errorMessage = 'Unable to play this station. The stream may be offline.';
      _isBuffering = false;
      _isPlaying = false;
      await _player.stop(); // Stop player to clear notification state
      notifyListeners();
    }
  }

  /// Toggle between play and pause.
  void togglePlay() {
    if (_currentStation == null) return;

    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  /// Initialize system volume listener and configuration
  Future<void> _initVolumeController() async {
    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      _volume = 1.0;
      return;
    }

    try {
      // Hide system volume UI overlay to avoid clashing with our custom slider
      await FlutterVolumeController.updateShowSystemUI(false);

      final double? systemVolume = await FlutterVolumeController.getVolume();
      if (systemVolume != null) {
        _volume = systemVolume;
        _player.setVolume(systemVolume);
        notifyListeners();
      }

      FlutterVolumeController.addListener((vol) {
        _volume = vol;
        _player.setVolume(vol);
        notifyListeners();
      });
    } catch (e) {
      developer.log('Failed to initialize volume controller: $e');
    }
  }

  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);

    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      try {
        FlutterVolumeController.setVolume(_volume);
      } catch (e) {
        developer.log('Failed to set system volume: $e');
      }
    }

    // Also update player internal volume so it works on iOS/Android Simulators
    _player.setVolume(_volume);

    notifyListeners();
  }

  /// Toggle mute state.
  void toggleMute() {
    if (isMuted) {
      setVolume(_previousVolume > 0.0 ? _previousVolume : 0.8);
    } else {
      _previousVolume = _volume;
      setVolume(0.0);
    }
  }

  // --- Sleep Timer Methods ---

  /// Start a sleep timer to pause playback after a duration.
  void startSleepTimer(Duration duration) {
    cancelSleepTimer();

    _sleepTimeLeftSeconds = duration.inSeconds;
    notifyListeners();

    // Countdown tick timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimeLeftSeconds > 0) {
        _sleepTimeLeftSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });

    // Expiry timer
    _sleepTimer = Timer(duration, () async {
      developer.log('Sleep timer triggered. Stopping playback.');

      // Beautiful fade out player volume logic (affects player only, keeping system volume intact)
      const int steps = 10;
      final double initialPlayerVolume = _player.volume;
      final double stepVolume = initialPlayerVolume / steps;

      for (int i = 1; i <= steps; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        await _player.setVolume(
          (initialPlayerVolume - (stepVolume * i)).clamp(0.0, 1.0),
        );
      }

      // Stop player
      _player.pause();

      // Restore original player volume for next playback
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
    _sleepTimeLeftSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      try {
        FlutterVolumeController.removeListener();
      } catch (e) {
        developer.log('Failed to remove volume listener: $e');
      }
    }
    _player.dispose();
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
