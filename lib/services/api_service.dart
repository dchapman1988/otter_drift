import 'package:dio/dio.dart';
import 'config.dart';
import 'auth_service.dart';

class ApiService {
  static late final Dio _dio;

  static void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor to automatically include auth headers
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure we have a valid token
        if (!await AuthService.isAuthenticated()) {
          final authSuccess = await AuthService.authenticate();
          if (!authSuccess) {
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
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized responses
        if (error.response?.statusCode == 401) {
          print('Received 401, attempting re-authentication...');
          
          // Try to re-authenticate
          final reAuthSuccess = await AuthService.reAuthenticate();
          if (reAuthSuccess) {
            // Retry the original request
            final token = await AuthService.getToken();
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (retryError) {
                print('Retry after re-authentication failed: $retryError');
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
      final response = await dio.post('/api/v1/auth/login', data: {
        'client_id': clientId(),
        'api_key': apiKey(),
      });
      
      print('POST /api/v1/auth/login - Status: ${response.statusCode}');
      print('Response: ${response.data}');
      
      return response.statusCode == 200 && response.data != null;
    } catch (e) {
      print('POST /api/v1/auth/login - Error: $e');
      return false;
    }
  }
}
