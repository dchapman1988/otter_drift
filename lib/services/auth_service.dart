import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'security_config.dart';
import 'secure_logger.dart';
import 'retry_service.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static String? _cachedToken;

  /// Check if the user is currently authenticated with a valid token
  static Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null) {
        SecureLogger.logDebug('No token found - user not authenticated');
        return false;
      }

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        SecureLogger.logAuth(
          'Token expired - clearing and marking as unauthenticated',
        );
        await clearToken();
        return false;
      }

      SecureLogger.logDebug('User is authenticated with valid token');
      return true;
    } catch (e) {
      SecureLogger.logError('Error checking authentication status', error: e);
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
        await clearToken();
      }

      return null;
    } catch (e, stackTrace) {
      SecureLogger.logError(
        'Failed to retrieve token from secure storage',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Authenticate with the backend and store the JWT token
  static Future<bool> authenticate() async {
    try {
      SecureLogger.logAuth('Starting authentication process');

      // Validate configuration before attempting authentication
      SecurityConfig.validateConfiguration();

      final timeoutConfig = SecurityConfig.getTimeoutConfig();
      final dio = Dio(
        BaseOptions(
          baseUrl: SecurityConfig.getBaseUrl(),
          connectTimeout: timeoutConfig.connectTimeout,
          receiveTimeout: timeoutConfig.receiveTimeout,
          sendTimeout: timeoutConfig.sendTimeout,
        ),
      );

      final authData = {
        'client_id': SecurityConfig.getClientId(),
        'api_key': SecurityConfig.getApiKey(),
      };

      SecureLogger.logRequest('POST', '/api/v1/auth/login', body: authData);

      final response = await RetryService.executeDioRequestWithRetry(
        () => dio.post('/api/v1/auth/login', data: authData),
        operationName: 'authentication',
      );

      SecureLogger.logResponse(
        response.statusCode ?? 0,
        '/api/v1/auth/login',
        body: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: _tokenKey, value: token);
          _cachedToken = token;

          SecureLogger.logAuth(
            'Authentication successful',
            data: {
              'tokenLength': token.length,
              'tokenExpiration': await getTokenExpiration(),
            },
          );

          return true;
        }
      }

      SecureLogger.logAuth(
        'Authentication failed: Invalid response',
        data: {
          'statusCode': response.statusCode,
          'responseData': response.data,
        },
      );

      return false;
    } catch (e) {
      SecureLogger.logError('Authentication failed', error: e);
      return false;
    }
  }

  /// Re-authenticate if the current token is expired or invalid
  static Future<bool> reAuthenticate() async {
    SecureLogger.logAuth('Starting re-authentication process');
    await clearToken();
    return await authenticate();
  }

  /// Clear the stored token
  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      _cachedToken = null;
      SecureLogger.logAuth('Token cleared from secure storage');
    } catch (e) {
      SecureLogger.logError('Failed to clear token', error: e);
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
    } catch (e, stackTrace) {
      SecureLogger.logError(
        'Failed to decode token expiration',
        error: e,
        stackTrace: stackTrace,
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
    } catch (e, stackTrace) {
      SecureLogger.logError(
        'Failed to determine token expiration threshold',
        error: e,
        stackTrace: stackTrace,
      );
      return true;
    }
  }

  /// Get token payload for debugging
  static Future<Map<String, dynamic>?> getTokenPayload() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      return JwtDecoder.decode(token);
    } catch (e, stackTrace) {
      SecureLogger.logError(
        'Failed to decode token payload',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
