import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/player.dart';
import 'api_service.dart';
import 'secure_logger.dart';

class PlayerAuthService {
  static const String _tokenKey = 'player_jwt_token';
  static const String _playerKey = 'player_data';
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static String? _cachedToken;
  static Player? _cachedPlayer;

  /// Check if the player is currently authenticated with a valid token
  static Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null) {
        SecureLogger.logDebug('No player token found - user not authenticated');
        return false;
      }
      
      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        SecureLogger.logAuth('Player token expired - clearing and marking as unauthenticated');
        await clearAuth();
        return false;
      }
      
      SecureLogger.logDebug('Player is authenticated with valid token');
      return true;
    } catch (e) {
      SecureLogger.logError('Error checking player authentication status', error: e);
      return false;
    }
  }

  /// Get the current JWT token from secure storage
  static Future<String?> getToken() async {
    try {
      if (_cachedToken != null) {
        // Check if cached token is still valid
        if (!JwtDecoder.isExpired(_cachedToken!)) {
          return _cachedToken;
        } else {
          _cachedToken = null;
        }
      }

      final token = await _storage.read(key: _tokenKey);
      if (token != null && !JwtDecoder.isExpired(token)) {
        _cachedToken = token;
        return token;
      } else if (token != null) {
        // Token is expired, remove it
        await clearAuth();
      }
      
      return null;
    } catch (e) {
      SecureLogger.logError('PlayerAuthService.getToken error', error: e);
      return null;
    }
  }

  /// Get the current player data
  static Future<Player?> getCurrentPlayer() async {
    try {
      if (_cachedPlayer != null) {
        return _cachedPlayer;
      }

      final playerJson = await _storage.read(key: _playerKey);
      if (playerJson != null) {
        // Try to parse as JSON first (new format)
        try {
          final decoded = Uri.decodeComponent(playerJson);
          final parts = decoded.split('&');
          final playerData = <String, dynamic>{};
          
          for (final part in parts) {
            final keyValue = part.split('=');
            if (keyValue.length == 2) {
              final key = keyValue[0];
              final value = keyValue[1];
              
              // Convert numeric values
              if (key == 'id' || key == 'total_score' || key == 'games_played') {
                playerData[key] = int.tryParse(value) ?? 0;
              } else {
                playerData[key] = value;
              }
            }
          }
          
          _cachedPlayer = Player.fromJson(playerData);
          return _cachedPlayer;
        } catch (e) {
          SecureLogger.logError('Failed to parse player data', error: e);
        }
      }
      
      return null;
    } catch (e) {
      SecureLogger.logError('PlayerAuthService.getCurrentPlayer error', error: e);
      return null;
    }
  }

  /// Sign up a new player
  static Future<AuthResult> signUp({
    required String email,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      SecureLogger.logAuth('Starting player sign up process');
      
      final response = await ApiService.post('/players.json', data: {
        'player': {
          'email': email,
          'username': username,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }
      });

      SecureLogger.logResponse(response.statusCode ?? 0, '/players', body: response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = _extractTokenFromResponse(response);
        final player = _extractPlayerFromResponse(response);
        
        if (token != null && player != null) {
          await _storeAuthData(token, player);
          SecureLogger.logAuth('Player sign up successful', data: {
            'playerId': player.id,
            'username': player.username,
          });
          return AuthResult.success(player: player);
        }
      }

      // Handle validation errors
      if (response.statusCode == 422) {
        final errors = response.data['errors'] as Map<String, dynamic>?;
        return AuthResult.failure(
          message: 'Validation failed',
          errors: errors,
        );
      }

      return AuthResult.failure(
        message: response.data['message'] ?? 'Sign up failed',
      );
    } catch (e) {
      SecureLogger.logError('Player sign up failed', error: e);
      if (e is DioException) {
        final response = e.response;
        if (response?.statusCode == 422) {
          // Log the full response for debugging
          SecureLogger.logError('422 Validation Error Response', error: response?.data);
          
          final errors = response?.data['errors'] as Map<String, dynamic>?;
          final message = response?.data['message'] as String?;
          final error = response?.data['error'] as String?;
          
          return AuthResult.failure(
            message: message ?? error ?? 'Validation failed',
            errors: errors,
          );
        }
        // Log other error responses
        SecureLogger.logError('Sign up error response', error: response?.data);
        
        return AuthResult.failure(
          message: response?.data['message'] as String? ?? 
                   response?.data['error'] as String? ?? 
                   'Sign up failed',
        );
      }
      return AuthResult.failure(message: 'Network error occurred');
    }
  }

  /// Sign in an existing player
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      SecureLogger.logAuth('Starting player sign in process');
      
      final response = await ApiService.post('/players/sign_in.json', data: {
        'player': {
          'email': email,
          'password': password,
        }
      });

      SecureLogger.logResponse(response.statusCode ?? 0, '/players/sign_in', body: response.data);
      SecureLogger.logDebug('Response headers: ${response.headers.map}');

      if (response.statusCode == 200) {
        final token = _extractTokenFromResponse(response);
        final player = _extractPlayerFromResponse(response);
        
        if (token != null && player != null) {
          await _storeAuthData(token, player);
          SecureLogger.logAuth('Player sign in successful', data: {
            'playerId': player.id,
            'username': player.username,
            'tokenLength': token.length,
          });
          return AuthResult.success(player: player);
        } else if (player == null) {
          SecureLogger.logError('Failed to extract player from response');
          return AuthResult.failure(message: 'Invalid player data received');
        } else {
          SecureLogger.logError('Failed to extract JWT token from response');
          return AuthResult.failure(message: 'No authentication token received');
        }
      }

      return AuthResult.failure(
        message: response.data['message'] ?? 'Sign in failed',
      );
    } catch (e) {
      SecureLogger.logError('Player sign in failed', error: e);
      if (e is DioException) {
        final response = e.response;
        return AuthResult.failure(
          message: response?.data['message'] ?? 'Sign in failed',
        );
      }
      return AuthResult.failure(message: 'Network error occurred');
    }
  }

  /// Sign out the current player
  static Future<bool> signOut() async {
    try {
      SecureLogger.logAuth('Starting player sign out process');
      
      // Call the backend sign out endpoint
      try {
        await ApiService.delete('/players/sign_out.json');
        SecureLogger.logAuth('Backend sign out successful');
      } catch (e) {
        // Even if backend call fails, we should clear local auth
        SecureLogger.logError('Backend sign out failed, but clearing local auth', error: e);
      }

      // Clear local authentication data
      await clearAuth();
      SecureLogger.logAuth('Player sign out successful');
      return true;
    } catch (e) {
      SecureLogger.logError('Player sign out failed', error: e);
      return false;
    }
  }

  /// Clear all authentication data
  static Future<void> clearAuth() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _playerKey);
      _cachedToken = null;
      _cachedPlayer = null;
      SecureLogger.logAuth('Player authentication data cleared');
    } catch (e) {
      SecureLogger.logError('Failed to clear player auth data', error: e);
    }
  }

  /// Store authentication data securely
  static Future<void> _storeAuthData(String token, Player player) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      
      // Store player data as query string for easy parsing
      final playerQueryString = Uri(queryParameters: player.toJson().map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      await _storage.write(key: _playerKey, value: playerQueryString);
      
      _cachedToken = token;
      _cachedPlayer = player;
    } catch (e) {
      SecureLogger.logError('Failed to store player auth data', error: e);
      rethrow;
    }
  }

  /// Extract JWT token from response headers or body
  static String? _extractTokenFromResponse(Response response) {
    // The token is in the Authorization response header
    // Rails devise-jwt sends it as: "Bearer <token>"
    
    // Try to get authorization header (Dio lowercases header names)
    final authHeader = response.headers.value('authorization');
    
    if (authHeader != null) {
      SecureLogger.logDebug('Found authorization header: ${authHeader.substring(0, 20)}...');
      
      if (authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7).trim();
        SecureLogger.logAuth('Successfully extracted JWT token from Authorization header');
        return token;
      } else if (authHeader.startsWith('bearer ')) {
        final token = authHeader.substring(7).trim();
        SecureLogger.logAuth('Successfully extracted JWT token from authorization header (lowercase)');
        return token;
      } else {
        // Token without Bearer prefix
        SecureLogger.logAuth('Found token without Bearer prefix');
        return authHeader.trim();
      }
    }

    // Fallback: Check response body
    final data = response.data as Map<String, dynamic>?;
    final token = data?['token'] as String? ?? data?['jwt'] as String?;
    if (token != null) {
      SecureLogger.logDebug('Found token in response body');
      return token;
    }
    
    SecureLogger.logError('No JWT token found in response');
    SecureLogger.logDebug('Available headers: ${response.headers.map.keys.toList()}');
    return null;
  }

  /// Extract player data from response
  static Player? _extractPlayerFromResponse(Response response) {
    try {
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;

      // Check for player data in various possible locations
      final playerData = data['player'] as Map<String, dynamic>? ??
                        data['user'] as Map<String, dynamic>? ??
                        data;

      return Player.fromJson(playerData);
    } catch (e) {
      SecureLogger.logError('Failed to extract player from response', error: e);
      return null;
    }
  }

  /// Get token expiration time
  static Future<DateTime?> getTokenExpiration() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      
      final decodedToken = JwtDecoder.decode(token);
      final exp = decodedToken['exp'] as int?;
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      return null;
    } catch (e) {
      SecureLogger.logError('PlayerAuthService.getTokenExpiration error', error: e);
      return null;
    }
  }

  /// Check if token will expire within the specified duration
  static Future<bool> isTokenExpiringSoon({Duration threshold = const Duration(minutes: 5)}) async {
    try {
      final expiration = await getTokenExpiration();
      if (expiration == null) return true;
      
      final now = DateTime.now();
      return expiration.isBefore(now.add(threshold));
    } catch (e) {
      SecureLogger.logError('PlayerAuthService.isTokenExpiringSoon error', error: e);
      return true;
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final String? message;
  final Player? player;
  final Map<String, dynamic>? errors;

  const AuthResult._({
    required this.isSuccess,
    this.message,
    this.player,
    this.errors,
  });

  factory AuthResult.success({required Player player}) {
    return AuthResult._(
      isSuccess: true,
      player: player,
    );
  }

  factory AuthResult.failure({
    required String message,
    Map<String, dynamic>? errors,
  }) {
    return AuthResult._(
      isSuccess: false,
      message: message,
      errors: errors,
    );
  }
}

