# Labhouse FM - Premium Flutter Radio Tuner

A state-of-the-art Flutter radio streaming application featuring a dark-themed glassmorphic design, custom canvas animations, and a rich user experience. It pulls live global radio stations from the community-driven **Radio Browser API**, streams audio seamlessly using **`just_audio`**, and offers high-fidelity features like local favorites persistence, playback history, and a sleep timer.

---

## 🌟 Key Features

*   **Global Radio Database:** Browse and stream tens of thousands of active stations worldwide using the free, open-source Radio Browser API.
*   **Deep Glassmorphism UI:** Immersive dark design featuring glass translucent containers, glowing gradients, custom badges, and modern typography (Outfit & Inter).
*   **Organic Wave Visualizer:** A custom-painted fluid audio wave visualizer that animates procedurally when music is playing and lies flat when paused.
*   **Interactive Mini-Player:** A persistent floating bottom player allowing quick play/pause controls, metadata reading, and smooth sliding transitions to the full-screen view.
*   **Sleep Timer:** Set custom durations (5, 15, 30, 45, 60 minutes) to automatically fade out the audio and pause playback.
*   **Local Persistence:** Instantly save stations to a dedicated **Favorites** deck or view recently played stations in the **History** row.
*   **Live Stream Resolution:** Resolves active API servers dynamically on boot and utilizes resolved stream URLs to handle redirects and playlists natively.

---

## 🛠 Tech Stack

*   **Core Framework:** Flutter (3.x) & Dart
*   **Audio Engine:** [just_audio](https://pub.dev/packages/just_audio) (High-fidelity live stream buffer management)
*   **HTTP Client:** [dio](https://pub.dev/packages/dio) (Network requests, custom User-Agent, and connection timeouts)
*   **State Management:** [provider](https://pub.dev/packages/provider) (Legible, reactive change notifications)
*   **Local Persistence:** [shared_preferences](https://pub.dev/packages/shared_preferences) (Key-value disk storage for Favorites and History)
*   **UI Helpers:** [shimmer](https://pub.dev/packages/shimmer) (Premium skeleton loading effects), [google_fonts](https://pub.dev/packages/google_fonts) (Premium modern typography)

---

## 📂 Project Architecture

```
lib/
├── main.dart                  # Sets up global Providers, Theme, and Launches Splash Screen
├── core/
│   ├── theme/
│   │   └── app_theme.dart     # Defines colors, gradients, and custom TextThemes
│   └── services/
│       ├── api_service.dart   # Dio client fetching Radio Browser API endpoints
│       ├── favorites_service.dart # Local persistence for favorited stations
│       └── history_service.dart   # Local persistence for played history
├── models/
│   └── station_model.dart     # Station data representation & JSON parser
├── providers/
│   ├── favorites_provider.dart # Manages favoriting reactive state
│   └── radio_provider.dart    # Manages play/pause, volume, sleep timer, & search queries
└── ui/
    ├── widgets/
    │   ├── glass_container.dart # Translucent blur styling layout
    │   ├── station_tile.dart    # List tiles for radio entries
    │   ├── mini_player.dart     # Floating bottom player bar
    │   └── visualizer.dart      # CustomPainter overlapping sine waves
    └── screens/
        ├── splash_screen.dart   # Pulsing launch logo & initialization sequence
        ├── home_screen.dart     # Main browse page with search and decks
        └── player_screen.dart   # Full-screen player with volume and sleep timer
```

---

## 🚀 How to Run the Application

### 📋 Prerequisites

Before running the application, make sure you have the following installed on your system:
*   **Flutter SDK** (Version `>= 3.12.2`) - [Install Flutter](https://docs.flutter.dev/get-started/install)
*   **CocoaPods** (for iOS builds)
*   **Xcode** (Required for running on iOS Simulator / Physical Device)
*   **Android Studio & SDK** (Required for running on Android Emulator / Physical Device)

---

### 📥 Setup Instructions

1.  **Clone the Repository** and navigate to the project root:
    ```bash
    cd /Users/vicajilau/Developer/Flutter/flutter-radio-tuner
    ```

2.  **Download Dependencies:**
    Fetch the Dart packages resolved in `pubspec.yaml`:
    ```bash
    flutter pub get
    ```

3.  **Run Static Code Analysis:**
    Ensure there are no compilation or syntax issues:
    ```bash
    flutter analyze
    ```

4.  **Run Automated Tests:**
    Execute the unit test suite to verify model and state provider logic:
    ```bash
    flutter test
    ```

---

### 📱 Launching on Simulators/Emulators

#### Running on iOS (Simulator)

1.  List and start the iOS simulator:
    ```bash
    flutter emulators --launch apple_ios_simulator
    ```
2.  Deploy and run the app on the active iOS simulator:
    ```bash
    flutter run -d iPhone
    ```

#### Running on Android (Emulator)

1.  List and start the Android emulator:
    ```bash
    flutter emulators --launch 16_KB_Medium_Phone
    ```
2.  Deploy and run the app:
    ```bash
    flutter run -d android
    ```

---

## 🔧 Platform Configurations (Details)

### Android Configuration
*   **Permissions:** Request internet access and network state check in `android/app/src/main/AndroidManifest.xml`.
*   **Cleartext Traffic:** Enabled `android:usesCleartextTraffic="true"` to allow streaming from radio stations serving on HTTP protocols rather than HTTPS.

### iOS Configuration
*   **Background Audio:** Configured `UIBackgroundModes` with `audio` in `ios/Runner/Info.plist` to keep streams playing when locking the phone or backgrounding the app.
*   **Transport Security:** Added `NSAppTransportSecurity` configuration allowing arbitrary HTTP loads to prevent iOS from blocking non-HTTPS radio streams.
