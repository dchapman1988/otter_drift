import 'package:dio/dio.dart';
import 'security_config.dart';
import 'auth_service.dart';
import 'player_auth_service.dart';
import 'secure_logger.dart';
import 'retry_service.dart';
import 'certificate_pinning_service.dart';

class ApiService {
  static late final Dio _dio;

  static void _initializeDio() {
    final timeoutConfig = SecurityConfig.getTimeoutConfig();

    _dio = Dio(
      BaseOptions(
        baseUrl: SecurityConfig.getBaseUrl(),
        connectTimeout: timeoutConfig.connectTimeout,
        receiveTimeout: timeoutConfig.receiveTimeout,
        sendTimeout: timeoutConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add certificate pinning interceptor
    _dio.interceptors.add(CertificatePinningService.createPinningInterceptor());

    // Add retry interceptor
    _dio.interceptors.add(RetryService.createRetryInterceptor());

    // Add interceptor to automatically include auth headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            SecureLogger.logRequest(
              options.method,
              options.uri.toString(),
              headers: options.headers,
              body: options.data,
            );

            // Log authorization header specifically for debugging
            if (options.headers['Authorization'] != null) {
              SecureLogger.logDebug(
                'Authorization header being sent: ${options.headers['Authorization']}',
              );
            }

            // Check if this is a player authentication endpoint (sign up/sign in)
            final isPlayerSignUpOrSignIn =
                options.uri.path == '/players' ||
                options.uri.path == '/players.json' ||
                options.uri.path == '/players/sign_in' ||
                options.uri.path == '/players/sign_in.json';

            // Don't add auth headers for sign up/sign in
            if (isPlayerSignUpOrSignIn) {
              SecureLogger.logDebug(
                'Skipping auth for sign up/sign in endpoint',
              );
            } else {
              // For all other endpoints, check if player is authenticated
              if (await PlayerAuthService.isAuthenticated()) {
                final token = await PlayerAuthService.getToken();
                if (token != null) {
                  options.headers['Authorization'] =
                      'Bearer $token'; // Add "Bearer " prefix back
                  SecureLogger.logDebug(
                    'Added player JWT token to Authorization header (length: ${token.length})',
                  );
                  SecureLogger.logDebug(
                    'Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
                  );
                } else {
                  SecureLogger.logError(
                    'Player is authenticated but token is null',
                  );
                }
              } else {
                // For player endpoints, only use player JWT authentication
                // No fallback to system authentication for player-specific endpoints
                SecureLogger.logDebug(
                  'Player not authenticated - request will be unauthorized',
                );
              }
            }

            handler.next(options);
          } catch (e) {
            SecureLogger.logError('Error in request interceptor', error: e);
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Request interceptor error: $e',
                type: DioExceptionType.unknown,
              ),
            );
          }
        },
        onResponse: (response, handler) async {
          SecureLogger.logResponse(
            response.statusCode ?? 0,
            response.requestOptions.uri.toString(),
            headers: response.headers.map,
            body: response.data,
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          SecureLogger.logError(
            'API request failed: ${error.requestOptions.method} ${error.requestOptions.uri}',
            error: error,
          );

          // Handle 401 unauthorized responses
          if (error.response?.statusCode == 401) {
            SecureLogger.logAuth('Received 401, attempting re-authentication');

            final isPlayerAuthEndpoint = error.requestOptions.uri.path
                .startsWith('/players');

            if (isPlayerAuthEndpoint) {
              // For player endpoints, clear player auth and let the user re-login
              await PlayerAuthService.clearAuth();
              handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error: 'Player authentication expired - please sign in again',
                  type: DioExceptionType.unknown,
                  response: error.response,
                ),
              );
              return;
            } else {
              // For system endpoints, try to re-authenticate
              final reAuthSuccess = await AuthService.reAuthenticate();
              if (reAuthSuccess) {
                // Retry the original request
                final token = await AuthService.getToken();
                if (token != null) {
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $token';

                  try {
                    SecureLogger.logAuth(
                      'Retrying request after successful re-authentication',
                    );
                    final response = await _dio.fetch(error.requestOptions);
                    handler.resolve(response);
                    return;
                  } catch (retryError) {
                    SecureLogger.logError(
                      'Retry after re-authentication failed',
                      error: retryError,
                    );
                  }
                }
              }

              // If re-authentication failed or retry failed, reject with auth error
              handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  error:
                      'System authentication failed - please check your credentials',
                  type: DioExceptionType.unknown,
                  response: error.response,
                ),
              );
              return;
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  static Dio get dio {
    if (!_isInitialized) {
      _initializeDio();
      _isInitialized = true;
    }
    return _dio;
  }

  static bool _isInitialized = false;

  /// Make a GET request
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a POST request
  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a PUT request
  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a PATCH request
  static Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a DELETE request
  static Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Check if the API is reachable
  static Future<bool> checkConnection() async {
    try {
      // Use a simple endpoint that doesn't require authentication
      final response = await dio.get('/hello');
      SecureLogger.logResponse(
        response.statusCode ?? 0,
        '/hello',
        body: response.data,
      );
      return response.statusCode == 200;
    } catch (e, stackTrace) {
      SecureLogger.logError(
        'GET /hello failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Test authentication endpoint
  static Future<bool> testAuthentication() async {
    try {
      SecureLogger.logAuth('Testing authentication endpoint');

      final response = await dio.post(
        '/api/v1/auth/login',
        data: {
          'client_id': SecurityConfig.getClientId(),
          'api_key': SecurityConfig.getApiKey(),
        },
      );

      SecureLogger.logResponse(
        response.statusCode ?? 0,
        '/api/v1/auth/login',
        body: response.data,
      );

      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      SecureLogger.logError('Authentication endpoint test failed', error: e);
      return false;
    }
  }
}
