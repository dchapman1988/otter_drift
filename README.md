# 🦦 Otter Drift

> An arcade-style Flutter + Flame game where you guide an otter down river rapids while collecting items and dodging hazards.

[![Flutter](https://img.shields.io/badge/Flutter-3.38-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10-blue.svg)](https://dart.dev)
[![Flame](https://img.shields.io/badge/Flame-1.33-orange.svg)](https://flame-engine.org)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey.svg)](https://flutter.dev)
[![CI](https://github.com/dchapman1988/otter_drift/workflows/Flutter%20CI/badge.svg)](.github/workflows/dart.yml)

## 📸 Screenshots

<img width="517" height="1029" alt="Gameplay Screenshot" src="https://github.com/user-attachments/assets/d5963007-d7a3-4d49-a3ea-5a607d8c15d7" />
<img width="517" height="1029" alt="Menu Screenshot" src="https://github.com/user-attachments/assets/97459875-1033-43a5-ba9f-2a39a4bbdb34" />
<img width="517" height="1029" alt="Gameplay 1" src="https://github.com/user-attachments/assets/c4e7c0d9-37d7-4e63-9063-a4fb821c0aef" />
<img width="517" height="1029" alt="Gameplay 2" src="https://github.com/user-attachments/assets/6100a19c-c2b1-4e5a-9260-4f40f8f55e3a" />
<img width="517" height="1029" alt="Gameplay 3" src="https://github.com/user-attachments/assets/20fe3029-e2b2-4e29-93a1-6977cf152271" />
<img width="517" height="1029" alt="Gameplay 4" src="https://github.com/user-attachments/assets/56b1de6b-eeb0-49aa-a5ce-81e0cecbe7b6" />

## ✨ Features

- 🎮 **Smooth Gameplay** - Fast-paced river navigation with responsive tap controls
- 🎯 **Score System** - Collect lilies and avoid logs to build your high score
- ❤️  **Health Management** - Start with 3 hearts, collect power-ups to restore health
- 📈 **Progressive Difficulty** - River speed increases over time for added challenge
- 🏆 **Leaderboards** - Compete globally with authenticated players
- 👤 **Player Profiles** - Track achievements, game history, and statistics
- 🔐 **Secure Authentication** - JWT-based auth with certificate pinning support
- 🎵 **Immersive Audio** - Background music and sound effects
- 🎨 **Beautiful Graphics** - Animated sprites and smooth visuals
- 🔄 **Guest Mode** - Play without an account (scores won't sync)

## 🎮 How to Play

### Objective
Stay alive as long as possible while racking up the highest score!

### Controls
- **Tap anywhere** on the screen to move the otter horizontally toward the tap position

### Game Elements

- **🪵 Logs** (60% spawn rate)
  - Avoid these! Colliding with a log costs one heart
  - Repeated collisions end your run

- **🌸 Lilies** (25% spawn rate)
  - Collect these for **10 points** each
  - Focus on gathering as many as possible for a high score

- **❤️ Hearts** (15% spawn rate)
  - Restore one heart when collected (max 3 hearts)
  - Essential for survival on longer runs

### Difficulty Progression

- **Starting Speed**: 120 px/s
- **Speed Increase**: ~10% every 20 seconds
- **Maximum Speed**: 240 px/s (capped)

### Game Over

When you run out of hearts, you'll see:
- Final score
- Statistics (lilies collected, hearts collected)
- Option to submit score (if authenticated)
- Play Again or return to Main Menu

## Getting Started

### Prerequisites

- **Flutter 3.38+** (check with `flutter --version`)
- **Dart SDK 3.10+** (bundled with Flutter)
- **Backend API** - Rails API server running (see [Backend Repository](https://github.com/dchapman1988/otter_drift_api/))

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd otter_drift
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API credentials**

   Run the app with required environment variables:
   ```bash
   flutter run \
     --dart-define=API_KEY=your_64_char_hex_key \
     --dart-define=CLIENT_ID=game_client_1 \
     --dart-define=API_BASE=http://localhost:3000
   ```

   > **Note**: Android emulators automatically use `http://10.0.2.2:3000` instead of `localhost`

4. **Build for release**
   ```bash
   flutter build apk --dart-define=API_KEY=prod_key_here
   # or for iOS
   flutter build ios --dart-define=API_KEY=prod_key_here
   ```

## Project Structure

```
otter_drift/
├── lib/
│   ├── game/                    # Flame game engine code
│   │   ├── components/          # Game entities (Otter, Logs, Lilies, Hearts)
│   │   ├── hud/                 # Heads-up display components
│   │   └── otter_game.dart      # Main game class
│   ├── screens/                 # Flutter UI screens
│   │   ├── auth/                # Login/Signup screens
│   │   ├── game/                # Game screen wrapper
│   │   ├── menu/                # Main menu screen
│   │   └── profile/             # Profile management screens
│   ├── services/                # Business logic & API integration
│   │   ├── api_service.dart     # HTTP client wrapper
│   │   ├── auth_service.dart    # Authentication handling
│   │   ├── backend.dart         # API endpoint definitions
│   │   └── security_config.dart # Certificate pinning config
│   ├── models/                  # Data models
│   ├── widgets/                 # Reusable UI widgets
│   └── util/                    # Utilities (RNG, etc.)
├── assets/                      # Game assets
│   ├── images/                  # Sprites and UI graphics
│   └── audio/                   # Sound effects and music
├── test/                        # Test suite
│   ├── game/                    # Game logic tests
│   ├── screens/                 # Widget tests
│   └── util/                    # Utility tests
└── pubspec.yaml                 # Dependencies and asset configuration
```

## Testing

Run the test suite:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/util/rng_test.dart

# Run with coverage
flutter test --coverage
```

Currently passing: **11 tests** (RNG utility tests)

## Configuration

### Required Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `API_KEY` | 64-character hex API key for backend authentication | *Required* |
| `CLIENT_ID` | Client identifier for the API | `game_client_1` |
| `API_BASE` | Base URL for the backend API | `http://localhost:3000` |

### Security

- **JWT Tokens**: Stored securely via `flutter_secure_storage`
- **Certificate Pinning**: Configurable in `lib/services/security_config.dart`
- **Sensitive Logging**: `SecureLogger` automatically masks sensitive fields

## Backend Integration

This project requires a Rails API backend. See the [backend repository](https://github.com/dchapman1988/otter_drift_api/) for setup instructions.

The backend must provide:
- Authentication endpoints (login, signup, refresh)
- User profile management
- Leaderboard API
- Game session submission endpoint

Default API routes:
- `/api/v1/auth/*` - Authentication
- `/api/v1/players/*` - Player data
- `/api/v1/leaderboard` - Global leaderboard
- `/api/v1/game_sessions` - Score submission

## Troubleshooting

### Common Issues

**Missing API Key Error**
```
Error: API_KEY is required
```
**Solution**: Run with `--dart-define=API_KEY=your_key_here`

**401 Authentication Errors**
- Verify backend is running
- Check API key matches backend configuration
- Ensure device/emulator can reach the API URL
- Android emulator should use `http://10.0.2.2:3000` instead of `localhost`

**Assets Not Loading**
- Run `flutter pub get` after modifying `pubspec.yaml`
- Verify asset paths in `pubspec.yaml` match file structure
- For web builds, check asset bundling configuration

**Audio Issues**
- Ensure audio files are in `assets/audio/` directory
- Check file formats are supported (WAV recommended)

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Dependencies

### Core
- **Flutter** - UI framework
- **Flame 1.33** - Game engine
- **Flame Audio** - Audio system

### Networking
- **Dio** - HTTP client
- **Connectivity Plus** - Network status

### Storage & Security
- **Flutter Secure Storage** - Secure credential storage
- **Shared Preferences** - App preferences
- **JWT Decoder** - Token parsing

See `pubspec.yaml` for complete dependency list.

---

Made with ❤️  and 🦦

**Happy Drifting!** 🏞️
