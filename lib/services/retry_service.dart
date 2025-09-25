import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'security_config.dart';
import 'secure_logger.dart';

/// Service for handling retry logic with exponential backoff
class RetryService {
  static final Random _random = Random();
  
  /// Execute a function with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    String? operationName,
  }) async {
    final retryConfig = config ?? SecurityConfig.getRetryConfig();
    final name = operationName ?? 'operation';
    
    Exception? lastException;
    
    for (int attempt = 1; attempt <= retryConfig.maxAttempts; attempt++) {
      try {
        SecureLogger.logDebug('Attempting $name (attempt $attempt/${retryConfig.maxAttempts})');
        
        final result = await operation();
        
        if (attempt > 1) {
          SecureLogger.logInfo('$name succeeded on attempt $attempt');
        }
        
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        SecureLogger.logError('$name failed on attempt $attempt', error: e);
        
        // Don't retry on the last attempt
        if (attempt == retryConfig.maxAttempts) {
          break;
        }
        
        // Don't retry on certain types of errors
        if (!_shouldRetry(e)) {
          SecureLogger.logInfo('$name failed with non-retryable error: $e');
          break;
        }
        
        // Calculate delay with jitter
        final delay = _calculateDelay(attempt, retryConfig);
        
        SecureLogger.logDebug('Retrying $name in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      }
    }
    
    SecureLogger.logError('$name failed after ${retryConfig.maxAttempts} attempts');
    throw lastException ?? Exception('Operation failed after ${retryConfig.maxAttempts} attempts');
  }
  
  /// Execute a Dio request with retry logic
  static Future<Response<T>> executeDioRequestWithRetry<T>(
    Future<Response<T>> Function() request, {
    RetryConfig? config,
    String? operationName,
  }) async {
    return await executeWithRetry<Response<T>>(
      request,
      config: config,
      operationName: operationName,
    );
  }
  
  /// Check if an error should trigger a retry
  static bool _shouldRetry(dynamic error) {
    if (error is DioException) {
      // Retry on network errors and timeouts
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          // Retry on 5xx server errors, but not on 4xx client errors
          final statusCode = error.response?.statusCode;
          if (statusCode != null && statusCode >= 500) {
            return true;
          }
          return false;
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
        case DioExceptionType.badCertificate:
          return false;
      }
    }
    
    // Retry on other network-related exceptions
    if (error is SocketException || 
        error is TimeoutException || 
        error is HttpException) {
      return true;
    }
    
    return false;
  }
  
  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    // Exponential backoff: baseDelay * (backoffMultiplier ^ (attempt - 1))
    final exponentialDelay = config.baseDelay * 
        pow(config.backoffMultiplier, attempt - 1);
    
    // Cap at maxDelay
    final cappedDelay = exponentialDelay > config.maxDelay 
        ? config.maxDelay 
        : exponentialDelay;
    
    // Add jitter (±25% of the delay)
    final jitterRange = cappedDelay.inMilliseconds * 0.25;
    final jitter = _random.nextDouble() * jitterRange * 2 - jitterRange;
    
    final finalDelay = cappedDelay.inMilliseconds + jitter;
    
    return Duration(milliseconds: finalDelay.round().clamp(0, config.maxDelay.inMilliseconds));
  }
  
  /// Create a retry interceptor for Dio
  static Interceptor createRetryInterceptor({RetryConfig? config}) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (!_shouldRetry(error)) {
          handler.next(error);
          return;
        }
        
        final retryConfig = config ?? SecurityConfig.getRetryConfig();
        final requestOptions = error.requestOptions;
        
        // Try to retry the request
        for (int attempt = 1; attempt < retryConfig.maxAttempts; attempt++) {
          try {
            SecureLogger.logDebug(
              'Retrying ${requestOptions.method} ${requestOptions.path} (attempt ${attempt + 1}/${retryConfig.maxAttempts})'
            );
            
            final delay = _calculateDelay(attempt + 1, retryConfig);
            await Future.delayed(delay);
            
            final response = await Dio().fetch(requestOptions);
            handler.resolve(response);
            return;
          } catch (retryError) {
            SecureLogger.logError(
              'Retry attempt ${attempt + 1} failed for ${requestOptions.method} ${requestOptions.path}',
              error: retryError
            );
            
            if (attempt == retryConfig.maxAttempts - 1) {
              // Last attempt failed
              handler.next(error);
              return;
            }
          }
        }
        
        handler.next(error);
      },
    );
  }
}
