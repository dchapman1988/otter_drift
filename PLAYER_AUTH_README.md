# Player Authentication System

This document describes the player authentication system integrated into the Otter Drift Flutter game.

## Overview

The authentication system provides:
- Player registration and login
- JWT token-based authentication
- Secure token storage using flutter_secure_storage
- Guest mode for unauthenticated play
- Player profile management
- Game session tracking with player association

## Architecture

### Core Components

1. **Player Model** (`lib/models/player.dart`)
   - Represents player data with fields: id, email, username, displayName, totalScore, gamesPlayed
   - Includes JSON serialization/deserialization

2. **PlayerAuthService** (`lib/services/player_auth_service.dart`)
   - Handles player authentication operations
   - Manages JWT token storage and validation
   - Provides sign up, sign in, and sign out functionality

3. **PlayerApiService** (`lib/services/player_api_service.dart`)
   - Handles player-specific API calls
   - Manages game session submission with player context
   - Provides player profile and statistics endpoints

4. **AuthStateService** (`lib/services/auth_state_service.dart`)
   - Manages authentication state across the app
   - Provides streams for auth state changes
   - Handles state transitions between authenticated, unauthenticated, and guest modes

5. **AuthWrapper** (`lib/widgets/auth_wrapper.dart`)
   - Main authentication wrapper widget
   - Handles routing between login, game, and profile screens
   - Manages authentication state display

### UI Components

1. **LoginScreen** (`lib/screens/auth/login_screen.dart`)
   - Email/password login form
   - Form validation
   - Error handling and display
   - Links to sign up and guest mode

2. **SignUpScreen** (`lib/screens/auth/signup_screen.dart`)
   - User registration form
   - Email, username, password, and confirmation fields
   - Validation error handling
   - Links to sign in and guest mode

3. **ProfileScreen** (`lib/screens/profile/profile_screen.dart`)
   - Player profile display
   - Statistics and achievements
   - Logout functionality
   - Links to game history and leaderboard

## API Endpoints

The system expects the following Rails API endpoints:

### Authentication
- `POST /players` - Player registration (Devise registrations#create)
- `POST /players/sign_in` - Player login (Devise sessions#create)
- `DELETE /players/sign_out` - Player logout (Devise sessions#destroy)

### Password Management
- `GET /players/password/new` - New password form
- `GET /players/password/edit` - Edit password form
- `POST /players/password` - Create password reset
- `PATCH /players/password` - Update password
- `PUT /players/password` - Update password (alternative)

### Player Data
- `GET /players/profile` - Get player profile
- `PUT /players/profile` - Update player profile
- `GET /players/stats` - Get player statistics
- `GET /players/game_history` - Get player's game history

### Game Sessions
- `POST /api/v1/game_sessions` - Submit game session (with player context if authenticated)

### Leaderboard
- `GET /api/v1/scores/leaderboard` - Get leaderboard with player position

## Authentication Flow

1. **App Launch**: AuthWrapper checks for existing authentication
2. **Unauthenticated**: Shows LoginScreen
3. **Login/Signup**: PlayerAuthService handles authentication
4. **Success**: AuthStateService updates state, shows game
5. **Guest Mode**: Player can play without authentication
6. **Profile Access**: Authenticated players can view profile and stats

## Security Features

- JWT token validation with expiration checking
- Secure token storage using flutter_secure_storage
- Automatic token inclusion in API headers
- Token refresh handling
- Secure logout with token cleanup

## Game Integration

- Game sessions are automatically associated with authenticated players
- Guest mode allows play without authentication
- Player information is displayed in the game UI
- Score submission includes player context when authenticated

## Usage

### Basic Authentication Check
```dart
final isAuthenticated = await BackendService.isPlayerAuthenticated();
final player = await BackendService.getCurrentPlayer();
```

### Sign Up
```dart
final result = await BackendService.signUpPlayer(
  email: 'user@example.com',
  username: 'username',
  password: 'password',
  passwordConfirmation: 'password',
);

if (result.isSuccess) {
  // Handle success
} else {
  // Handle error
  print(result.message);
}
```

### Sign In
```dart
final result = await BackendService.signInPlayer(
  email: 'user@example.com',
  password: 'password',
);
```

### Sign Out
```dart
await BackendService.signOutPlayer();
```

## State Management

The AuthStateService provides reactive state management:

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

## Error Handling

The system includes comprehensive error handling:
- Network errors
- Validation errors from the API
- Authentication failures
- Token expiration
- Secure storage errors

All errors are logged using the existing SecureLogger system.

## Dependencies

- `dio` - HTTP client
- `flutter_secure_storage` - Secure token storage
- `jwt_decoder` - JWT token validation
- `uuid` - Session ID generation

## Future Enhancements

- Password reset functionality
- Social authentication (Google, Apple)
- Push notifications for achievements
- Offline mode with sync
- Player avatar upload
- Friend system and multiplayer features

