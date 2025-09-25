import 'package:dio/dio.dart';
import 'security_config.dart';
import 'auth_service.dart';
import 'secure_logger.dart';
import 'retry_service.dart';
import 'certificate_pinning_service.dart';

class ApiService {
  static late final Dio _dio;

  static void _initializeDio() {
    final timeoutConfig = SecurityConfig.getTimeoutConfig();
    
    _dio = Dio(BaseOptions(
      baseUrl: SecurityConfig.getBaseUrl(),
      connectTimeout: timeoutConfig.connectTimeout,
      receiveTimeout: timeoutConfig.receiveTimeout,
      sendTimeout: timeoutConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add certificate pinning interceptor
    _dio.interceptors.add(CertificatePinningService.createPinningInterceptor());
    
    // Add retry interceptor
    _dio.interceptors.add(RetryService.createRetryInterceptor());

    // Add interceptor to automatically include auth headers
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          SecureLogger.logRequest(
            options.method, 
            options.uri.toString(),
            headers: options.headers,
            body: options.data,
          );
          
          // Ensure we have a valid token
          if (!await AuthService.isAuthenticated()) {
            SecureLogger.logAuth('No valid token found, attempting authentication');
            final authSuccess = await AuthService.authenticate();
            if (!authSuccess) {
              SecureLogger.logError('Authentication failed during request');
              handler.reject(DioException(
                requestOptions: options,
                error: 'Authentication failed',
                type: DioExceptionType.unknown,
              ));
              return;
            }
          }

          // Add authorization header
          final token = await AuthService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            SecureLogger.logDebug('Added authorization header to request');
          }

          handler.next(options);
        } catch (e) {
          SecureLogger.logError('Error in request interceptor', error: e);
          handler.reject(DioException(
            requestOptions: options,
            error: 'Request interceptor error: $e',
            type: DioExceptionType.unknown,
          ));
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
          
          // Try to re-authenticate
          final reAuthSuccess = await AuthService.reAuthenticate();
          if (reAuthSuccess) {
            // Retry the original request
            final token = await AuthService.getToken();
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              
              try {
                SecureLogger.logAuth('Retrying request after successful re-authentication');
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (retryError) {
                SecureLogger.logError('Retry after re-authentication failed', error: retryError);
              }
            }
          }
          
          // If re-authentication failed or retry failed, reject with auth error
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: 'Authentication failed - please check your credentials',
            type: DioExceptionType.unknown,
            response: error.response,
          ));
          return;
        }

        handler.next(error);
      },
    ));
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
      print('GET /hello - Status: ${response.statusCode}');
      print('Response: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('GET /hello - Error: $e');
      return false;
    }
  }

  /// Test authentication endpoint
  static Future<bool> testAuthentication() async {
    try {
      SecureLogger.logAuth('Testing authentication endpoint');
      
      final response = await dio.post('/api/v1/auth/login', data: {
        'client_id': SecurityConfig.getClientId(),
        'api_key': SecurityConfig.getApiKey(),
      });
      
      SecureLogger.logResponse(response.statusCode ?? 0, '/api/v1/auth/login', body: response.data);
      
      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      SecureLogger.logError('Authentication endpoint test failed', error: e);
      return false;
    }
  }
}
