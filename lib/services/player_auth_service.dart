import 'dart:convert';

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
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
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
      try {
        final isExpired = JwtDecoder.isExpired(token);
        SecureLogger.logDebug(
          'JWT expiration check: isExpired=$isExpired, token length=${token.length}',
        );

        if (isExpired) {
          SecureLogger.logAuth(
            'Player token expired - clearing and marking as unauthenticated',
          );
          await clearAuth();
          return false;
        }
      } catch (e) {
        SecureLogger.logError('Error checking JWT expiration', error: e);
        SecureLogger.logDebug(
          'Token that caused error: ${token.length > 50 ? "${token.substring(0, 50)}..." : token}',
        );
        // If we can't decode the token, it's invalid
        await clearAuth();
        return false;
      }

      SecureLogger.logDebug('Player is authenticated with valid token');
      return true;
    } catch (e) {
      SecureLogger.logError(
        'Error checking player authentication status',
        error: e,
      );
      return false;
    }
  }

  /// Get the current JWT token from secure storage
  static Future<String?> getToken() async {
    try {
      if (_cachedToken != null) {
        // Check if cached token is still valid
        try {
          final isExpired = JwtDecoder.isExpired(_cachedToken!);
          SecureLogger.logDebug(
            'PlayerAuthService.getToken: Cached token expiration check: isExpired=$isExpired',
          );

          if (!isExpired) {
            SecureLogger.logDebug(
              'PlayerAuthService.getToken: Returning cached token (length: ${_cachedToken!.length})',
            );
            return _cachedToken;
          } else {
            SecureLogger.logDebug(
              'PlayerAuthService.getToken: Cached token is expired, clearing it',
            );
            _cachedToken = null;
          }
        } catch (e) {
          SecureLogger.logError(
            'Error checking cached token expiration',
            error: e,
          );
          _cachedToken = null;
        }
      }

      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        try {
          final isExpired = JwtDecoder.isExpired(token);
          SecureLogger.logDebug(
            'PlayerAuthService.getToken: Storage token expiration check: isExpired=$isExpired',
          );

          if (!isExpired) {
            _cachedToken = token;
            SecureLogger.logDebug(
              'PlayerAuthService.getToken: Retrieved token from storage (length: ${token.length})',
            );
            SecureLogger.logDebug(
              'PlayerAuthService.getToken: Token preview: ${token.length > 20 ? "${token.substring(0, 20)}..." : token}',
            );
            return token;
          } else {
            // Token is expired, remove it
            SecureLogger.logDebug(
              'PlayerAuthService.getToken: Token from storage is expired, clearing auth',
            );
            await clearAuth();
          }
        } catch (e) {
          SecureLogger.logError(
            'Error checking storage token expiration',
            error: e,
          );
          SecureLogger.logDebug(
            'Storage token that caused error: ${token.length > 50 ? "${token.substring(0, 50)}..." : token}',
          );
          await clearAuth();
        }
      } else {
        SecureLogger.logDebug(
          'PlayerAuthService.getToken: No token found in storage',
        );
        SecureLogger.logDebug(
          'PlayerAuthService.getToken: Storage key used: $_tokenKey',
        );
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
          final decodedJson = jsonDecode(playerJson) as Map<String, dynamic>;
          _cachedPlayer = Player.fromJson(decodedJson);
          return _cachedPlayer;
        } catch (jsonError) {
          SecureLogger.logError(
            'Failed to parse player data as JSON',
            error: jsonError,
          );

          // Fallback to legacy query-string format
          try {
            final decoded = Uri.decodeComponent(playerJson);
            final parts = decoded.split('&');
            final playerData = <String, dynamic>{};

            for (final part in parts) {
              final keyValue = part.split('=');
              if (keyValue.length == 2) {
                final key = keyValue[0];
                final value = keyValue[1];

                if (key == 'id' ||
                    key == 'total_score' ||
                    key == 'games_played') {
                  playerData[key] = int.tryParse(value) ?? 0;
                } else if (value.toLowerCase() == 'null' || value.isEmpty) {
                  playerData[key] = null;
                } else {
                  playerData[key] = value;
                }
              }
            }

            _cachedPlayer = Player.fromJson(playerData);
            return _cachedPlayer;
          } catch (legacyError) {
            SecureLogger.logError(
              'Failed to parse player data from legacy format',
              error: legacyError,
            );
          }
        }
      }

      return null;
    } catch (e) {
      SecureLogger.logError(
        'PlayerAuthService.getCurrentPlayer error',
        error: e,
      );
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

      final response = await ApiService.post(
        '/players.json',
        data: {
          'player': {
            'email': email,
            'username': username,
            'password': password,
            'password_confirmation': passwordConfirmation,
          },
        },
      );

      SecureLogger.logResponse(
        response.statusCode ?? 0,
        '/players',
        body: response.data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = _extractTokenFromResponse(response);
        final player = _extractPlayerFromResponse(response);

        if (token != null && player != null) {
          await _storeAuthData(token, player);
          SecureLogger.logAuth(
            'Player sign up successful',
            data: {'playerId': player.id, 'username': player.username},
          );
          return AuthResult.success(player: player);
        }
      }

      // Handle validation errors
      if (response.statusCode == 422) {
        final errors = response.data['errors'] as Map<String, dynamic>?;
        return AuthResult.failure(message: 'Validation failed', errors: errors);
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
          SecureLogger.logError(
            '422 Validation Error Response',
            error: response?.data,
          );

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
          message:
              response?.data['message'] as String? ??
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

      final response = await ApiService.post(
        '/players/sign_in.json',
        data: {
          'player': {'email': email, 'password': password},
        },
      );

      SecureLogger.logResponse(
        response.statusCode ?? 0,
        '/players/sign_in',
        body: response.data,
      );
      SecureLogger.logDebug('Response headers: ${response.headers.map}');

      if (response.statusCode == 200) {
        SecureLogger.logDebug('=== SIGN IN RESPONSE PROCESSING ===');
        SecureLogger.logDebug('Response status: ${response.statusCode}');
        SecureLogger.logDebug('Response headers: ${response.headers.map}');
        SecureLogger.logDebug('Response body: ${response.data}');

        final token = _extractTokenFromResponse(response);
        final player = _extractPlayerFromResponse(response);

        SecureLogger.logDebug(
          'Sign in response processing: token=${token != null ? "present" : "null"}, player=${player != null ? "present" : "null"}',
        );

        if (token != null && player != null) {
          SecureLogger.logDebug(
            'Both token and player extracted successfully, storing auth data...',
          );
          await _storeAuthData(token, player);
          SecureLogger.logAuth(
            'Player sign in successful',
            data: {
              'playerId': player.id,
              'username': player.username,
              'tokenLength': token.length,
            },
          );
          return AuthResult.success(player: player);
        } else if (player == null) {
          SecureLogger.logError('Failed to extract player from response');
          return AuthResult.failure(message: 'Invalid player data received');
        } else {
          SecureLogger.logError('Failed to extract JWT token from response');
          return AuthResult.failure(
            message: 'No authentication token received',
          );
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
        SecureLogger.logError(
          'Backend sign out failed, but clearing local auth',
          error: e,
        );
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
      SecureLogger.logDebug(
        'Storing auth data: token length=${token.length}, player id=${player.id}',
      );
      SecureLogger.logDebug('Storage key: $_tokenKey');

      await _storage.write(key: _tokenKey, value: token);
      SecureLogger.logDebug('Token stored successfully');

      // Verify token was stored
      final storedToken = await _storage.read(key: _tokenKey);
      SecureLogger.logDebug(
        'Token verification: stored=${storedToken != null}, length=${storedToken?.length ?? 0}',
      );

      final sanitizedPlayerMap = _sanitizePlayerData(player.toJson());
      await _storage.write(
        key: _playerKey,
        value: jsonEncode(sanitizedPlayerMap),
      );
      SecureLogger.logDebug('Player data stored successfully');

      _cachedToken = token;
      _cachedPlayer = player;

      SecureLogger.logDebug('Auth data caching completed');
    } catch (e) {
      SecureLogger.logError('Failed to store player auth data', error: e);
      rethrow;
    }
  }

  /// Update stored player data while preserving the existing token
  static Future<void> updateStoredPlayer(Player player, {String? token}) async {
    try {
      final effectiveToken = token ?? await getToken();
      if (effectiveToken == null) {
        SecureLogger.logError(
          'Cannot update stored player data: token is null',
        );
        return;
      }

      await _storeAuthData(effectiveToken, player);
      SecureLogger.logDebug('Stored updated player data successfully');
    } catch (e) {
      SecureLogger.logError('Failed to update stored player data', error: e);
      rethrow;
    }
  }

  /// Extract JWT token from response headers or body
  static String? _extractTokenFromResponse(Response response) {
    // The token is in the Authorization response header
    // Rails devise-jwt sends it as: "Bearer <token>"

    SecureLogger.logDebug('=== JWT Token Extraction Debug ===');
    SecureLogger.logDebug('Response headers: ${response.headers.map}');
    SecureLogger.logDebug('Response status: ${response.statusCode}');

    // Try to get authorization header (Dio lowercases header names)
    final authHeader = response.headers.value('authorization');

    if (authHeader != null) {
      SecureLogger.logDebug(
        'Found authorization header: ${authHeader.length > 20 ? "${authHeader.substring(0, 20)}..." : authHeader}',
      );
      SecureLogger.logDebug('Full authorization header: $authHeader');

      // Extract just the JWT token part (without "Bearer " prefix) for storage
      // But we'll add "Bearer " back when sending requests
      String token;
      if (authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7).trim();
      } else if (authHeader.startsWith('bearer ')) {
        token = authHeader.substring(7).trim();
      } else {
        token = authHeader.trim();
      }

      SecureLogger.logAuth(
        'Successfully extracted JWT token from Authorization header (length: ${token.length})',
      );
      SecureLogger.logDebug(
        'Token preview: ${token.length > 20 ? "${token.substring(0, 20)}..." : token}',
      );
      return token; // Return just the JWT token part
    }

    // Fallback: Check response body
    final data = response.data as Map<String, dynamic>?;
    final token = data?['token'] as String? ?? data?['jwt'] as String?;
    if (token != null) {
      SecureLogger.logDebug('Found token in response body');
      return token;
    }

    SecureLogger.logError('No JWT token found in response');
    SecureLogger.logDebug(
      'Available headers: ${response.headers.map.keys.toList()}',
    );
    SecureLogger.logDebug('=== End JWT Token Extraction Debug ===');
    return null;
  }

  /// Extract player data from response
  static Player? _extractPlayerFromResponse(Response response) {
    try {
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;

      // Check for player data in various possible locations
      final playerData =
          data['player'] as Map<String, dynamic>? ??
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
      SecureLogger.logError(
        'PlayerAuthService.getTokenExpiration error',
        error: e,
      );
      return null;
    }
  }

  /// Check if token will expire within the specified duration
  static Future<bool> isTokenExpiringSoon({
    Duration threshold = const Duration(minutes: 5),
  }) async {
    try {
      final expiration = await getTokenExpiration();
      if (expiration == null) return true;

      final now = DateTime.now();
      return expiration.isBefore(now.add(threshold));
    } catch (e) {
      SecureLogger.logError(
        'PlayerAuthService.isTokenExpiringSoon error',
        error: e,
      );
      return true;
    }
  }
}

Map<String, dynamic> _sanitizePlayerData(Map<String, dynamic> input) {
  final result = <String, dynamic>{};

  input.forEach((key, value) {
    if (value == null) {
      return;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      if (trimmed.toLowerCase() == 'null') return;
      result[key] = trimmed;
      return;
    }

    if (value is Map<String, dynamic>) {
      final nested = _sanitizePlayerData(value);
      if (nested.isNotEmpty) {
        result[key] = nested;
      }
      return;
    }

    result[key] = value;
  });

  return result;
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
    return AuthResult._(isSuccess: true, player: player);
  }

  factory AuthResult.failure({
    required String message,
    Map<String, dynamic>? errors,
  }) {
    return AuthResult._(isSuccess: false, message: message, errors: errors);
  }
}
