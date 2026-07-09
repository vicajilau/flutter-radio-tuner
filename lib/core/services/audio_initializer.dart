import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Helper class to initialize and configure system-level audio properties.
/// Sets up the [AudioSession] configuration for media playback and integrates
/// the [JustAudioBackground] service for background notification controls.
class AudioInitializer {
  /// Initializes the background audio service configurations and audio session policies
  static Future<void> initialize() async {
    // Configure audio session for background playback and iOS silent switch exclusion
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('AudioSession configuration failed: $e');
    }

    // Configure just_audio_background
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.vicajilau.radio_tuner.channel.audio',
        androidNotificationChannelName: 'Radio Tuner Playback',
        androidNotificationOngoing: true,
      );
    } catch (e) {
      debugPrint('JustAudioBackground init failed: $e');
    }
  }
}
