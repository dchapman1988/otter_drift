import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'config.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static String? _cachedToken;

  /// Check if the user is currently authenticated with a valid token
  static Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      
      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        await clearToken();
        return false;
      }
      
      return true;
    } catch (e) {
      print('AuthService.isAuthenticated error: $e');
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
    } catch (e) {
      print('AuthService.getToken error: $e');
      return null;
    }
  }

  /// Authenticate with the backend and store the JWT token
  static Future<bool> authenticate() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post('/api/v1/auth/login', data: {
        'client_id': clientId(),
        'api_key': apiKey(),
      });

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: _tokenKey, value: token);
          _cachedToken = token;
          print('Authentication successful');
          return true;
        }
      }
      
      print('Authentication failed: Invalid response');
      return false;
    } catch (e) {
      print('Authentication error: $e');
      if (e is DioException) {
        print('Status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
      }
      return false;
    }
  }

  /// Re-authenticate if the current token is expired or invalid
  static Future<bool> reAuthenticate() async {
    await clearToken();
    return await authenticate();
  }

  /// Clear the stored token
  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      _cachedToken = null;
      print('Token cleared');
    } catch (e) {
      print('AuthService.clearToken error: $e');
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
      print('AuthService.getTokenExpiration error: $e');
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
      print('AuthService.isTokenExpiringSoon error: $e');
      return true;
    }
  }

  /// Get token payload for debugging
  static Future<Map<String, dynamic>?> getTokenPayload() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      
      return JwtDecoder.decode(token);
    } catch (e) {
      print('AuthService.getTokenPayload error: $e');
      return null;
    }
  }
}
