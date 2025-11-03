# Otter Drift 🦦

A Flutter-based otter-themed game with comprehensive player authentication, secure JWT token management, and Rails API integration.

## 🎮 Game Features

- **Flame Game Engine**: Smooth otter swimming gameplay with sprite-based graphics
- **Player Authentication**: JWT-based login/signup with secure token storage
- **Guest Mode**: Play without authentication
- **Player Profiles**: View stats, edit profile information, and track game history
- **Achievements System**: Earn and display achievements with badges and points
- **Global Leaderboard**: Compete with other players and see top scores with rank badges
- **Secure API Integration**: Certificate pinning, retry logic, and comprehensive error handling
- **Collectibles**: Collect hearts (restore health) and lilies (score points)
- **Beautiful Game Over Screen**: Styled results screen with collection stats and score saving

## 🕹️ Gameplay

Otter Drift is a Flappy Bird-style game where you control an otter swimming down a river!

### How to Play
- **Tap anywhere** on the screen to move your otter to that position
- **Avoid logs** - Hitting a log costs you a heart ❤️
- **Collect hearts** - Restore health (max 3 hearts)
- **Collect lilies** - Earn 10 points each 🌸
- **Survive as long as possible** - Speed increases every 20 seconds!

### Game Mechanics
- **Hearts**: Start with 3 hearts, lose one per log collision
- **Score**: Lilies award 10 points each
- **Speed**: Starts at 120 pixels/sec, increases by 10% every 20 seconds (max 240)
- **Spawning**: 60% logs (obstacles), 25% lilies (points), 15% hearts (health)

### Sprite Assets
The game uses custom sprites:
- **Otter**: 64x64px - Player character
- **Log**: 96x48px - Obstacle
- **Lily**: 48x48px - Collectible (10 points)
- **Heart**: 48x48px - Health restoration

## 🚀 Quick Start

### Prerequisites
- Flutter 3.x
- Dart SDK
- Rails backend running on `localhost:3000` (or configure your API endpoint)

### Installation

1. **Clone and install dependencies**:
   ```bash
   git clone <repository-url>
   cd otter_drift
   flutter pub get
   ```

2. **Run with your API key**:
   ```bash
   # Development
   flutter run --dart-define=API_KEY=your_development_api_key_here
   
   # Production
   flutter build apk --dart-define=API_KEY=your_production_api_key_here
   ```

## 🔐 Authentication System

### Features
- **JWT Token Management**: Secure token storage using `flutter_secure_storage`
- **Player Registration/Login**: Email, username, password authentication
- **Guest Mode**: Play without creating an account
- **Profile Management**: Edit bio, favorite otter facts, title, location, and avatar
- **Statistics Tracking**: Total score, games played, and game history
- **Achievements Display**: View earned achievements with badges and points on profile
- **Leaderboard Integration**: View global rankings and compete with other players

### API Endpoints
The app expects these Rails API endpoints:

#### Authentication
- `POST /players` - Player registration
- `POST /players/sign_in` - Player login  
- `DELETE /players/sign_out` - Player logout

#### Player Data
- `GET /players/profile` - Get player profile
- `PUT /players/profile` - Update player profile
- `GET /players/stats` - Get player statistics
- `GET /players/game_history` - Get player's game history
- `GET /api/v1/players/{username}/achievements` - Get player achievements (public endpoint)

#### Game Sessions
- `POST /api/v1/game_sessions` - Submit game session (with player context if authenticated)

#### Leaderboard
- `GET /api/v1/leaderboard` - Get global leaderboard (public endpoint, supports limit parameter)

## 🛡️ Security Features

### Build-Time Security
- **API Key Validation**: 64-character hex validation at build time
- **Environment Variables**: Support for dev/staging/production environments
- **No Hardcoded Secrets**: All credentials injected via `--dart-define`

### Network Security
- **Certificate Pinning**: Configurable certificate validation for HTTPS endpoints
- **Retry Logic**: Exponential backoff with jitter for network failures
- **Timeout Configuration**: Appropriate timeouts for different network conditions

### Secure Logging
- **Production-Safe**: Sensitive data automatically masked in production builds
- **Debug Logging**: Full logging available in development mode
- **Structured Logging**: Timestamps and categorized log levels

## 📱 Usage Examples

### Basic Authentication
```dart
// Check authentication status
final isAuthenticated = await BackendService.isPlayerAuthenticated();
final player = await BackendService.getCurrentPlayer();

// Sign up a new player
final result = await BackendService.signUpPlayer(
  email: 'user@example.com',
  username: 'username',
  password: 'password',
  passwordConfirmation: 'password',
);

// Sign in
final result = await BackendService.signInPlayer(
  email: 'user@example.com',
  password: 'password',
);

// Sign out
await BackendService.signOutPlayer();
```

### Game Session Submission
```dart
// Submit game session (authentication handled automatically)
final result = await BackendService.saveScore(
  sessionId: 'session_123',
  playerName: 'Player1',
  seed: 42,
  startedAt: DateTime.now().subtract(Duration(minutes: 5)),
  endedAt: DateTime.now(),
  finalScore: 1500,
  gameDuration: 300.0,
  maxSpeedReached: 15.5,
  obstaclesAvoided: 12,
  liliesCollected: 8,
  heartsCollected: 5,
);
```

## 🏗️ Architecture

### Core Services
- **PlayerAuthService**: Handles authentication operations and token management
- **PlayerApiService**: Manages player-specific API calls
- **ApiService**: Centralized HTTP client with automatic authentication
- **AuthStateService**: Reactive state management for authentication
- **SecurityConfig**: Centralized security configuration and validation
- **BackendService**: Game session submission and leaderboard data

### Models
- **Player**: Core player data with profile information
- **PlayerProfile**: Extended profile data (bio, favorite otter fact, etc.)
- **PlayerAchievement**: Individual achievement with badge, points, and collection date
- **PlayerAchievements**: Wrapper for player achievements list
- **LeaderboardEntry**: Leaderboard entry with rank, score, and player info
- **LeaderboardResponse**: Wrapper for leaderboard data with totals
- **PlayerInfo**: Player information for leaderboard entries
- **GameSession**: Game session data for score submission

### UI Components
- **AuthWrapper**: Main authentication routing
- **LoginScreen/SignUpScreen**: Authentication forms
- **MainMenuScreen**: Post-login menu with game options
- **ProfileScreen**: Player profile, statistics, and achievements display
- **EditProfileScreen**: Profile editing interface
- **LeaderboardScreen**: Global leaderboard with rank badges and filtering
- **AchievementsList**: Widget for displaying player achievements
- **LeaderboardWidget**: Reusable leaderboard widget with pull-to-refresh
- **OtterGame**: Main game logic with Flame engine
- **HUD**: Game heads-up display with score, health, and game over screen

## 🔧 Configuration

### Environment Variables
| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `API_KEY` | ✅ Yes | 64-character hex API key | `your_64_character_hex_api_key_here` |
| `CLIENT_ID` | ❌ No | Client identifier (default: `game_client_1`) | `game_client_1` |

### Certificate Pinning (Optional)
Configure in `lib/services/security_config.dart`:
```dart
static const Map<String, List<String>> _certificatePins = {
  'yourdomain.com': [
    'sha256/YOUR_CERTIFICATE_PIN_HERE',
  ],
};
```

## 🚨 Security Best Practices

### ✅ DO
- Use `--dart-define=API_KEY=your_key` for builds
- Use different keys for dev/staging/production
- Keep example scripts with placeholder values
- Regularly audit codebase for hardcoded secrets

### ❌ DON'T
- Hardcode API keys in source code
- Commit `.env` files with real credentials
- Store secrets in version control
- Share API keys in documentation

## 🔍 Troubleshooting

### Common Issues

1. **Build fails with "API_KEY environment variable is required"**
   ```bash
   flutter run --dart-define=API_KEY=your_development_api_key_here
   ```

2. **Authentication fails**
   - Check Rails backend is running
   - Verify API key is correct
   - Check network connectivity
   - Review logs for detailed error information

3. **Certificate pinning fails**
   - Get correct certificate pin for your domain
   - Update pin in `security_config.dart`
   - Test with `CertificatePinningService.testCertificatePinning()`

## 📋 Dependencies

### Core Dependencies
- `flutter_secure_storage: ^9.2.2` - Secure token storage
- `jwt_decoder: ^2.0.1` - JWT token validation
- `dio: ^5.4.0` - HTTP client
- `crypto: ^3.0.5` - Cryptographic functions
- `uuid: ^4.2.1` - Session ID generation

### Game Dependencies
- `flame: ^1.15.0` - Game engine
- `flame_audio: ^2.0.2` - Audio support

## 🎯 Development Workflow

### Development
```bash
flutter run --dart-define=API_KEY=your_development_api_key_here
```

### Staging
```bash
flutter build apk --dart-define=API_KEY=staging_api_key_here
```

### Production
```bash
flutter build apk --dart-define=API_KEY=production_api_key_here
```

## 📁 Project Structure

```
lib/
├── game/                 # Flame game components
│   ├── components/      # Game entities (Otter, Log, Lily, Heart)
│   └── hud/            # Heads-up display and game over screen
├── models/              # Data models (Player, PlayerProfile)
├── screens/             # UI screens (auth, profile, menu)
├── services/            # Core services (auth, API, security)
├── util/                # Utility functions (RNG, etc.)
└── widgets/             # Reusable UI components
```

## 🔄 State Management

The app uses reactive state management with `StreamController`s:

```dart
// Listen to auth state changes
StreamBuilder<AuthState>(
  stream: AuthStateService().authStateStream,
  builder: (context, snapshot) {
    final state = snapshot.data;
    // Handle different states
  },
)

// Listen to player changes
StreamBuilder<Player?>(
  stream: AuthStateService().playerStream,
  builder: (context, snapshot) {
    final player = snapshot.data;
    // Handle player data
  },
)
```

## 🚀 Future Enhancements

- Password reset functionality
- Social authentication (Google, Apple)
- Push notifications for achievements
- Offline mode with sync
- Player avatar upload
- Friend system and multiplayer features
- Advanced statistics and charts
- Achievement progress tracking and unlock notifications
- Leaderboard time filters (daily, weekly, monthly)
- Achievement categories and filtering
- Local leaderboard caching for offline viewing

## 📞 Support

For issues related to:
- **API Integration**: Check Rails backend configuration
- **Authentication**: Review JWT token handling
- **Security**: Run security check script
- **Game Issues**: Check Flame engine documentation

---

**Built with ❤️ using Flutter and Flame**