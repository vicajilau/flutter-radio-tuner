<p align="center">
  <img src=".github/assets/app_icon_transparent.png" width="160" alt="Labhouse FM Logo" />
</p>

<p align="center">
  <a href="https://github.com/vicajilau/flutter-radio-tuner/actions/workflows/ci.yml">
    <img src="https://github.com/vicajilau/flutter-radio-tuner/actions/workflows/ci.yml/badge.svg" alt="Flutter CI" />
  </a>
</p>

# Labhouse FM - Premium Flutter Radio Tuner

A state-of-the-art Flutter mobile application for streaming live global radio stations. Built with a high-end dark glassmorphic design, custom canvas animations, and a decoupled architecture that is 100% testable.

---

## 📻 What the App Does & How It Works

**Labhouse FM** allows users to discover, search, and stream radio stations from around the world.

### Dynamic API Resolution & Data Fetching
On boot, the app does not rely on a hardcoded server. Instead, it contacts the community-driven **Radio Browser API** resolver at `https://all.api.radio-browser.info/json/servers` to dynamically find the best active, online mirror. Once a base URL is resolved, the app fetches:
*   **Popular Stations:** High-traffic stations using `/json/stations/topclick`.
*   **Popular Genres/Tags:** Top tags by station counts using `/json/tags`.
*   **Custom Searches:** Searches filtered by query name or tag using `/json/stations/search`.

### Seamless Background Audio
When a station is selected, the app resolves its streaming URL and plays it. It handles redirects and playlists natively, keeping playback alive even when the phone is locked or the application is in the background.

---

## 📦 Dependencies & Why We Use Them

The project relies on specific, curated packages to achieve an enterprise-grade experience:

### Audio & Playback Engine
*   **[just_audio](https://pub.dev/packages/just_audio):** The core audio engine. We use it for its high-fidelity buffering, seamless stream playing capability, and detailed playback state streams.
*   **[just_audio_background](https://pub.dev/packages/just_audio_background):** Integrates our playback service with the OS. It registers the app as a foreground service on Android and handles lock screen controls, notifications, and metadata updates on both Android and iOS.
*   **[audio_session](https://pub.dev/packages/audio_session):** Manages audio focus policies (e.g., pausing when a call is received, routing audio to headphones, and bypassing the physical mute switch on iOS for media playback).
*   **[flutter_volume_controller](https://pub.dev/packages/flutter_volume_controller):** Synchronizes the system hardware volume controls with the in-app player volume slider.

### Networking & State Management
*   **[dio](https://pub.dev/packages/dio):** A powerful HTTP client. Used to fetch data from the Radio Browser API, handling request timeouts, custom User-Agents, and JSON parsing.
*   **[provider](https://pub.dev/packages/provider):** A lightweight state management framework. We use it to register our dependency injection tree and notify UI widgets when playback, volume, or searches update.

### Data Persistence & UI UX
*   **[shared_preferences](https://pub.dev/packages/shared_preferences):** A persistent key-value store. Used to persist the user's favorite stations and recently played history list across application restarts.
*   **[shimmer](https://pub.dev/packages/shimmer):** Renders glowing placeholder animations during active data fetches to create a premium visual experience.
*   **[google_fonts](https://pub.dev/packages/google_fonts):** Loads premium typography (Outfit and Inter) dynamically without bloating the app package.
*   **[url_launcher](https://pub.dev/packages/url_launcher):** Opens a station's homepage website in the device's default web browser.

---

## 📂 Project Architecture

The codebase follows the **Repository Pattern** and enforces **Dependency Inversion** through constructor injection:

```
lib/
├── main.dart                  # Dependency Injection tree setup & MaterialApp entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart     # Central styling system (gradients, dark theme, typography)
│   ├── services/
│   │   ├── api_service.dart   # Service interface & implementation communicating with Radio Browser API
│   │   ├── audio_initializer.dart # Handles audio session initialization & background playback settings
│   │   ├── favorites_service.dart # Local persistence layer for favorited stations
│   │   └── history_service.dart   # Local persistence layer for playback history
│   └── repositories/
│       └── station_repository.dart # Aggregates API & local services (Single Source of Truth)
├── models/
│   └── station_model.dart     # Station serialization & field fallbacks
├── providers/
│   ├── favorites_provider.dart # Manages favorite lists and UI notifications
│   └── radio_provider.dart    # Manages player state, sleep timers, volume sync, and searches
└── ui/
    ├── widgets/
    │   ├── glass_container.dart # Glassmorphic visual container wrapping UI elements
    │   ├── visualizer.dart      # CustomPainter rendering glowing procedural waveforms
    │   ├── mini_player.dart     # Floating bottom player bar
    │   ├── station_tile.dart    # Individual station list item with equalizer animation
    │   ├── genre_selector.dart  # Genre selector chips row
    │   ├── favorite_card.dart   # Card representation of a favorite station
    │   ├── history_tile.dart    # Compact recently played item
    │   ├── sleep_timer_sheet.dart # Selection panel for sleep durations
    │   └── station_shimmer.dart # Loading skeleton placeholders
    └── screens/
        ├── splash_screen.dart   # Entry logo animations and API resolving sequences
        ├── home_screen.dart     # Main dashboard (search, decks, and error screens)
        └── player_screen.dart   # Full-screen player with volume and sleep timers
```

---

## 🚀 How to Run the Application

### 📋 Prerequisites
*   **Flutter SDK** (`>= 3.12.2`) - [Install Flutter](https://docs.flutter.dev/get-started/install)
*   **CocoaPods** (for iOS builds)
*   **Xcode** (Required for iOS builds)
*   **Android Studio & SDK** (Required for Android builds)

### 📥 Run Commands

1.  **Clone the Repository** and navigate to the project root:
    ```bash
    cd /Users/vicajilau/Developer/Flutter/flutter-radio-tuner
    ```

2.  **Download Packages:**
    ```bash
    flutter pub get
    ```

3.  **Run Static Analysis:**
    ```bash
    flutter analyze
    ```

4.  **Run Automated Tests:**
    ```bash
    flutter test
    ```

5.  **Run the App:**
    ```bash
    flutter run
    ```

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.


