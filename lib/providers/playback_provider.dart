import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/di/di_providers.dart';
import '../models/station_model.dart';
import '../core/repositories/station_repository.dart';

part 'playback_provider.g.dart';

/// Type-safe enum for representing playback errors and connection states.
enum PlaybackError {
  /// The internet connection is disconnected.
  noInternet,

  /// The audio stream URL failed to load (offline or invalid node).
  streamOffline,

  /// General playback engine or volume service exception.
  playbackError,
}

/// ============================================================================
/// PLAYBACK PROVIDER
/// ============================================================================
///
/// This provider is responsible exclusively for the audio playback lifecycle
/// and multimedia state management (Single Responsibility Principle).
///
/// **Key Responsibilities:**
/// 1. Orchestrates the physical [AudioPlayer] instance (`just_audio`) to stream radio URLs.
/// 2. Listens to live stream metadata (ICY metadata) and exposes the song/track title.
/// 3. Synchronizes system and application volume using `flutter_volume_controller`.
/// 4. Manages progressive sleep timers (fading out volume before pausing).
/// 5. Automatically pauses audio on internet loss and resumes playing upon recovery.
///
/// **Decoupling Rationale:**
/// Separating audio playback from the station browser / filters ensures that UI
/// text searches or country filter changes on the Home Screen do not trigger
/// rebuilds in the active player screen or disrupt the current audio session.
/// ============================================================================

/// Immutable state representing the active audio player session.
class PlaybackState {
  /// The station currently loaded in the player. Null if no station is loaded.
  final Station? currentStation;

  /// True if the audio player is actively playing stream buffers.
  final bool isPlaying;

  /// True if the stream is loading, buffering, or resolving URLs.
  final bool isBuffering;

  /// The current volume level, bounded between 0.0 (muted) and 1.0 (maximum).
  final double volume;

  /// The last non-zero volume recorded before muting. Used to restore volume.
  final double previousVolume;

  /// Type-safe error type in case stream loading or network connection fails.
  final PlaybackError? error;

  /// Number of seconds left before the active sleep timer stops playback.
  final int sleepTimeLeftSeconds;

  /// The current song title and artist retrieved in real-time from the stream (ICY metadata).
  final String? currentTrackTitle;

  PlaybackState({
    this.currentStation,
    this.isPlaying = false,
    this.isBuffering = false,
    this.volume = 0.8,
    this.previousVolume = 0.8,
    this.error,
    this.sleepTimeLeftSeconds = 0,
    this.currentTrackTitle,
  });

  /// Check whether the player is currently muted (volume is exactly 0).
  bool get isMuted => volume == 0.0;

  /// Check whether the sleep timer countdown is currently running.
  bool get isSleepTimerActive => sleepTimeLeftSeconds > 0;

  /// Return the remaining sleep timer duration formatted as MM:SS (e.g. "14:59").
  String get sleepTimeFormatted {
    if (sleepTimeLeftSeconds <= 0) {
      return '';
    }
    final int minutes = sleepTimeLeftSeconds ~/ 60;
    final int seconds = sleepTimeLeftSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Create a copy of the state with modified fields.
  /// Nullable values like [currentStation], [error], and [currentTrackTitle]
  /// use a generator function `Value? Function()?` to allow explicitly resetting them to null.
  PlaybackState copyWith({
    Station? Function()? currentStation,
    bool? isPlaying,
    bool? isBuffering,
    double? volume,
    double? previousVolume,
    PlaybackError? Function()? error,
    int? sleepTimeLeftSeconds,
    String? Function()? currentTrackTitle,
  }) {
    return PlaybackState(
      currentStation: currentStation != null
          ? currentStation()
          : this.currentStation,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      previousVolume: previousVolume ?? this.previousVolume,
      error: error != null ? error() : this.error,
      sleepTimeLeftSeconds: sleepTimeLeftSeconds ?? this.sleepTimeLeftSeconds,
      currentTrackTitle: currentTrackTitle != null
          ? currentTrackTitle()
          : this.currentTrackTitle,
    );
  }
}

/// Notifier managing system volume controls, sleep timer schedules, and audio playback streams.
@Riverpod(keepAlive: true)
class Playback extends _$Playback {
  final AudioPlayer _player = AudioPlayer();
  late final StationRepository _repository;

  Timer? _sleepTimer;
  Timer? _countdownTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Track whether the user wants the radio to play.
  /// Used to distinguish between a network pause and a user pause/stop.
  bool _userWantsToPlay = false;

  /// Counter to track the active async play task, canceling any older retry loops.
  int _activePlayCount = 0;

  /// Exposed getter to access the raw [AudioPlayer] if direct controller hooks are needed.
  AudioPlayer get player => _player;

  @override
  PlaybackState build() {
    // Resolve repository dependency via Riverpod DI
    _repository = ref.watch(stationRepositoryProvider);

    // Dispose listeners, streams, and player hardware resources when provider is destroyed
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _sleepTimer?.cancel();
      _countdownTimer?.cancel();
      _player.dispose();
    });

    // Defer synchronous stream listening and listeners setup to run immediately
    // after the initial PlaybackState is successfully registered in the ProviderScope.
    Future.microtask(() {
      _initPlayerListeners();
      _initConnectivityListener();
      _initVolumeController();
    });

    return PlaybackState();
  }

  /// Bind listeners to the physical player streams (playback status and ICY metadata).
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
          error: playerState.processingState == ProcessingState.completed
              ? () => null
              : null,
        );

        if (playerState.processingState == ProcessingState.completed) {
          state = state.copyWith(isPlaying: false);
        }
      },
      onError: (Object e) {
        debugPrint('Player Stream Error: $e');
        if (_userWantsToPlay && state.currentStation != null) {
          debugPrint('Attempting to recover from player stream error...');
          playStation(state.currentStation!, forceReload: true);
        } else {
          state = state.copyWith(
            error: () => PlaybackError.playbackError,
            isBuffering: false,
            isPlaying: false,
          );
        }
      },
    );

    // Listen to ICY Metadata changes to extract current song and artist titles dynamically
    _player.icyMetadataStream.listen(
      (icyMetadata) {
        final title = icyMetadata?.info?.title;
        debugPrint('Received ICY Metadata: $title');
        state = state.copyWith(currentTrackTitle: () => title);
      },
      onError: (Object e) {
        debugPrint('ICY Metadata stream error: $e');
      },
    );

    _player.setVolume(state.volume);
  }

  /// Bind listener to network connectivity changes.
  /// Performs auto-pausing on disconnect and automatic re-buffering once connection returns.
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final hasConnection = !results.contains(ConnectivityResult.none);

        if (!hasConnection) {
          // If internet connection is lost, pause if we were trying to play
          if (_userWantsToPlay) {
            debugPrint('Internet connection lost. Pausing playback.');
            await _player.pause();
            state = state.copyWith(
              isPlaying: false,
              error: () => PlaybackError.noInternet,
            );
          }
        } else {
          // If connection returns/changes and the user wants to play, re-trigger stream buffering
          if (_userWantsToPlay && state.currentStation != null) {
            final isPlayerStuck =
                _player.processingState == ProcessingState.buffering ||
                _player.processingState == ProcessingState.loading;
            if (!state.isPlaying || isPlayerStuck || state.error != null) {
              debugPrint(
                'Internet connection restored/changed. Re-buffering stream.',
              );
              state = state.copyWith(isBuffering: true, error: () => null);
              try {
                await playStation(state.currentStation!, forceReload: true);
              } catch (e) {
                debugPrint('Auto-reconnection failed: $e');
              }
            }
          }
        }
      },
      onError: (Object e) {
        debugPrint('Connectivity stream error: $e');
      },
    );
  }

  /// Initialize system volume and sync it with our player instance.
  Future<void> _initVolumeController() async {
    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTest) {
      state = state.copyWith(volume: 1.0);
      return;
    }

    try {
      // Hide the OS volume bar overlay since we display a custom volume slider in UI
      await FlutterVolumeController.updateShowSystemUI(false);

      final double? systemVolume = await FlutterVolumeController.getVolume();
      if (systemVolume != null) {
        state = state.copyWith(volume: systemVolume);
        _player.setVolume(systemVolume);
      }

      // Keep app volume and system volume perfectly synced
      FlutterVolumeController.addListener((vol) {
        state = state.copyWith(volume: vol);
        _player.setVolume(vol);
      });
    } catch (e) {
      debugPrint('Failed to initialize volume controller: $e');
    }
  }

  /// Play a selected radio station.
  ///
  /// Loads the audio stream URL, configures lock screen metadata/background tasks,
  /// saves the station into the local history database, and starts playing.
  /// Retries connection up to 3 times with delays if the initial load fails.
  Future<void> playStation(Station station, {bool forceReload = false}) async {
    // Check initial connectivity before trying to connect
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnection = !connectivityResults.contains(
      ConnectivityResult.none,
    );
    if (!hasConnection) {
      state = state.copyWith(
        currentStation: () => station,
        error: () => PlaybackError.noInternet,
        isBuffering: false,
        isPlaying: false,
      );
      _userWantsToPlay =
          true; // Mark as true so it auto-plays when internet returns!
      return;
    }

    if (!forceReload &&
        state.currentStation?.stationuuid == station.stationuuid &&
        _player.processingState == ProcessingState.ready) {
      togglePlay();
      return;
    }

    _userWantsToPlay = true;
    _activePlayCount++;
    final int myPlaySession = _activePlayCount;

    await _player.setVolume(state.volume);

    state = state.copyWith(
      currentStation: () => station,
      isBuffering: true,
      error: () => null,
      currentTrackTitle: () => null,
    );

    // Save playing station to history via the repository
    _repository.addHistory(station);

    int retries = 0;
    while (retries < 3) {
      if (!_userWantsToPlay || myPlaySession != _activePlayCount) {
        return;
      }

      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        await session.setActive(true);

        await _player.setVolume(state.volume);

        final String streamUrl = station.urlResolved.isNotEmpty
            ? station.urlResolved
            : station.url;

        debugPrint(
          'Loading live radio stream (Attempt ${retries + 1}): $streamUrl',
        );

        if (myPlaySession != _activePlayCount) {
          return;
        }

        // Set audio source with metadata matching background capabilities
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(streamUrl),
            tag: MediaItem(
              id: station.stationuuid,
              album: station.country.isNotEmpty
                  ? station.country
                  : 'Radio Tuner',
              title: station.name,
              artUri: station.favicon.isNotEmpty
                  ? Uri.tryParse(station.favicon)
                  : null,
            ),
          ),
        );

        if (!_userWantsToPlay || myPlaySession != _activePlayCount) {
          return;
        }
        _player.play();
        return; // Success!
      } catch (e) {
        debugPrint('Error playing stream (Attempt ${retries + 1}): $e');
        retries++;

        if (myPlaySession != _activePlayCount) {
          return;
        }

        if (retries >= 3 || !_userWantsToPlay) {
          state = state.copyWith(
            error: () => PlaybackError.streamOffline,
            isBuffering: false,
            isPlaying: false,
          );
          _userWantsToPlay = false; // Reset if all retries fail
          await _player.stop();
          return;
        }
        state = state.copyWith(isBuffering: true, error: () => null);
        debugPrint('Retrying stream in 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Toggle play and pause state for the active station.
  void togglePlay() {
    if (state.currentStation == null) {
      return;
    }

    if (state.isPlaying) {
      _userWantsToPlay = false;
      _activePlayCount++; // Invalidate any running retry loops
      _player.pause();
    } else {
      _userWantsToPlay = true;
      _player.play();
    }
  }

  /// Stop playback, cancel active sleep timers, and clear active station fields.
  Future<void> stopRadio() async {
    _userWantsToPlay = false;
    _activePlayCount++; // Invalidate any running retry loops
    cancelSleepTimer();
    state = state.copyWith(
      isBuffering: false,
      isPlaying: false,
      currentStation: () => null,
      currentTrackTitle: () => null,
      error: () => null,
    );
    await _player.stop();
  }

  /// Set the system and player volume level.
  void setVolume(double val) {
    final volume = val.clamp(0.0, 1.0);
    state = state.copyWith(volume: volume);

    final bool isTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      try {
        FlutterVolumeController.setVolume(volume);
      } catch (e) {
        debugPrint('Failed to set system volume: $e');
      }
    }

    _player.setVolume(volume);
  }

  /// Mute or restore volume levels.
  void toggleMute() {
    if (state.isMuted) {
      setVolume(state.previousVolume > 0.0 ? state.previousVolume : 0.8);
    } else {
      state = state.copyWith(previousVolume: state.volume);
      setVolume(0.0);
    }
  }

  /// Start a sleep timer to pause playback after a duration.
  ///
  /// Spawns a periodic timer to update the countdown in UI and schedules
  /// a fading process that smoothly lowers the volume before pausing the player.
  void startSleepTimer(Duration duration) {
    cancelSleepTimer();

    state = state.copyWith(sleepTimeLeftSeconds: duration.inSeconds);

    // Periodic timer to tick down seconds in UI
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.sleepTimeLeftSeconds > 0) {
        state = state.copyWith(
          sleepTimeLeftSeconds: state.sleepTimeLeftSeconds - 1,
        );
      } else {
        timer.cancel();
      }
    });

    // Sleep trigger timer
    _sleepTimer = Timer(duration, () async {
      debugPrint('Sleep timer triggered. Stopping playback.');
      _userWantsToPlay = false;
      _activePlayCount++; // Invalidate any running retry loops

      // Fade-out volume control
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

      // Restore initial volume level for when player starts next time
      await _player.setVolume(initialPlayerVolume);
      cancelSleepTimer();
    });
  }

  /// Cancel any active sleep timers and reset countdown seconds.
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = state.copyWith(sleepTimeLeftSeconds: 0);
  }
}
