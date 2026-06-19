import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/station_model.dart';
import '../core/repositories/station_repository.dart';

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

    // Sync volume from player to provider
    _player.volumeStream.listen((vol) {
      _volume = vol;
      notifyListeners();
    });
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

    _currentStation = station;
    _isBuffering = true;
    _errorMessage = null;
    notifyListeners();

    // Add to history list reactive state and DB
    _repository.addHistory(station);
    loadHistory(); // Reload history from SharedPreferences

    try {
      // Configure player volume before loading
      await _player.setVolume(_volume);

      // Use url_resolved as recommended by the API documentation
      final String streamUrl = station.urlResolved.isNotEmpty
          ? station.urlResolved
          : station.url;

      developer.log('Loading live radio stream: $streamUrl');
      await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));

      // Auto-play
      _player.play();
    } catch (e) {
      developer.log('Error playing stream: $e');
      _errorMessage = 'Unable to play this station. The stream may be offline.';
      _isBuffering = false;
      _isPlaying = false;
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

  /// Adjust the playback volume.
  void setVolume(double val) {
    _volume = val.clamp(0.0, 1.0);
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

      // Beautiful fade out volume logic
      const int steps = 10;
      final double initialVolume = _volume;
      final double stepVolume = initialVolume / steps;

      for (int i = 1; i <= steps; i++) {
        await Future.delayed(const Duration(milliseconds: 150));
        setVolume((initialVolume - (stepVolume * i)).clamp(0.0, 1.0));
      }

      // Stop player
      _player.pause();

      // Restore original volume for next playback
      setVolume(initialVolume);

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
    _player.dispose();
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
