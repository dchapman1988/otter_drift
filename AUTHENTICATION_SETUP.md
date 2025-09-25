# JWT Authentication Setup

This document explains how to set up and use JWT authentication in your Flutter app.

## Dependencies Added

The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_secure_storage: ^9.2.2  # For secure token storage
  jwt_decoder: ^2.0.1             # For JWT token validation
```

## Installation

Run the following command to install the new dependencies:

```bash
flutter pub get
```

## Configuration

### Environment Variables

You can configure the authentication credentials using environment variables:

```bash
# For development
flutter run --dart-define=CLIENT_ID=game_client_1 --dart-define=API_KEY=your_secret_key_here

# For production builds
flutter build apk --dart-define=CLIENT_ID=your_prod_client_id --dart-define=API_KEY=your_prod_api_key
```

### Default Values

If no environment variables are provided, the following defaults are used:
- `CLIENT_ID`: `game_client_1`
- `API_KEY`: `your_secret_key_here`

**Important**: Change the default API key in production!

## Services Overview

### 1. AuthService (`lib/services/auth_service.dart`)

Handles JWT token management and authentication:

- `authenticate()` - Authenticate with backend and store token
- `isAuthenticated()` - Check if user has valid token
- `getToken()` - Get current JWT token
- `reAuthenticate()` - Clear token and re-authenticate
- `clearToken()` - Remove stored token
- `getTokenExpiration()` - Get token expiration time
- `isTokenExpiringSoon()` - Check if token expires soon

### 2. ApiService (`lib/services/api_service.dart`)

HTTP client with automatic authentication:

- Automatically includes JWT token in requests
- Handles 401 responses by re-authenticating
- Retries failed requests after re-authentication
- Provides methods: `get()`, `post()`, `put()`, `delete()`

### 3. BackendService (`lib/services/backend.dart`)

Updated to use authenticated API calls:

- All existing methods now use JWT authentication
- Added authentication helper methods
- Maintains the same interface as before

## Usage Examples

### Basic Usage

```dart
import 'package:your_app/services/backend.dart';

// Save a game score (authentication handled automatically)
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
);
```

### Authentication Management

```dart
import 'package:your_app/services/backend.dart';

// Check if authenticated
final isAuth = await BackendService.isAuthenticated();

// Authenticate manually
final authSuccess = await BackendService.authenticate();

// Logout
await BackendService.logout();
```

### Complete Example

See `lib/services/auth_example.dart` for a complete working example.

## Authentication Flow

1. **First Request**: When any API call is made, the system checks for a valid token
2. **No Token**: If no token exists, it automatically authenticates using `client_id` and `api_key`
3. **Token Expired**: If the token is expired, it automatically re-authenticates
4. **401 Response**: If the server returns 401, it re-authenticates and retries the request
5. **Secure Storage**: Tokens are stored securely using `flutter_secure_storage`

## Error Handling

The system handles various error scenarios:

- **Network errors**: Logged and returned as null
- **Authentication failures**: Logged with detailed error information
- **Token expiration**: Automatically handled with re-authentication
- **401 responses**: Automatically retried after re-authentication

## Security Features

- **Secure Storage**: JWT tokens are stored using Flutter's secure storage
- **Token Validation**: Tokens are validated before use
- **Automatic Expiration**: Expired tokens are automatically cleared
- **Re-authentication**: Failed requests are retried after re-authentication

## Testing

To test the authentication system:

```dart
import 'package:your_app/services/auth_example.dart';

// Run the complete example
await AuthExample.runCompleteExample();
```

## Troubleshooting

### Common Issues

1. **Authentication fails**: Check your `client_id` and `api_key` configuration
2. **Network errors**: Ensure your Rails backend is running and accessible
3. **Token storage issues**: Check device permissions for secure storage

### Debug Information

The system provides detailed logging for debugging:

- Authentication attempts and results
- Token expiration checks
- API request/response details
- Error information with status codes

## Production Considerations

1. **Change default API key**: Never use the default API key in production
2. **Use environment variables**: Configure credentials via environment variables
3. **Monitor token expiration**: Consider implementing proactive token refresh
4. **Error handling**: Implement proper error handling in your UI
5. **Network timeouts**: Adjust timeout values based on your network conditions
