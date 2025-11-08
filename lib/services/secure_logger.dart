import 'dart:convert';
import 'dart:developer' as developer;

import 'security_config.dart';

/// Secure logging system that masks sensitive data in production
class SecureLogger {
  static const String _logPrefix = '[SecureLogger]';
  
  /// Log authentication events
  static void logAuth(String message, {Map<String, dynamic>? data}) {
    final sanitizedData = _sanitizeData(data);
    _log('AUTH', message, sanitizedData);
  }
  
  /// Log API requests
  static void logRequest(String method, String url, {Map<String, dynamic>? headers, dynamic body}) {
    final sanitizedHeaders = _sanitizeHeaders(headers);
    final sanitizedBody = _sanitizeBody(body);
    
    _log('REQUEST', '$method $url', {
      'headers': sanitizedHeaders,
      'body': sanitizedBody,
    });
  }
  
  /// Log API responses
  static void logResponse(int statusCode, String url, {Map<String, dynamic>? headers, dynamic body}) {
    final sanitizedHeaders = _sanitizeHeaders(headers);
    final sanitizedBody = _sanitizeBody(body);
    
    _log('RESPONSE', '$statusCode $url', {
      'headers': sanitizedHeaders,
      'body': sanitizedBody,
    });
  }
  
  /// Log errors
  static void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final sanitizedData = _sanitizeData(data);
    final logDetails = <String, dynamic>{
      if (error != null) 'error': error.toString(),
      if (sanitizedData != null && sanitizedData.isNotEmpty) 'data': sanitizedData,
    };

    _log(
      'ERROR',
      message,
      logDetails.isEmpty ? null : logDetails,
      stackTrace: stackTrace,
    );
  }
  
  /// Log security events
  static void logSecurity(String message, {Map<String, dynamic>? data}) {
    final sanitizedData = _sanitizeData(data);
    _log('SECURITY', message, sanitizedData);
  }
  
  /// Log general information
  static void logInfo(String message, {Map<String, dynamic>? data}) {
    final sanitizedData = _sanitizeData(data);
    _log('INFO', message, sanitizedData);
  }
  
  /// Log debug information (only in debug mode)
  static void logDebug(String message, {Map<String, dynamic>? data}) {
    if (SecurityConfig.isDebugMode()) {
      final sanitizedData = _sanitizeData(data);
      _log('DEBUG', message, sanitizedData);
    }
  }
  
  /// Internal logging method
  static void _log(
    String level,
    String message,
    Map<String, dynamic>? data, {
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final baseMessage = '$timestamp: $message';
    final loggerName = '$_logPrefix/$level';
    final logLevel = _levelToValue(level);

    developer.log(
      baseMessage,
      name: loggerName,
      level: logLevel,
      stackTrace: stackTrace,
    );

    if (data != null && data.isNotEmpty) {
      try {
        final jsonData = jsonEncode(data);
        developer.log(
          '$timestamp: $jsonData',
          name: '$loggerName/data',
          level: logLevel,
        );
      } catch (error, stack) {
        developer.log(
          '$timestamp: $data',
          name: '$loggerName/data',
          level: logLevel,
          error: error,
          stackTrace: stack,
        );
      }
    }
  }

  static int _levelToValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'REQUEST':
      case 'RESPONSE':
      case 'AUTH':
        return 900;
      case 'SECURITY':
        return 950;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
  
  /// Sanitize data to remove sensitive information
  static Map<String, dynamic>? _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      if (_isSensitiveKey(key)) {
        sanitized[entry.key] = _maskSensitiveValue(value);
      } else {
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized;
  }
  
  /// Sanitize headers to remove sensitive information
  static Map<String, dynamic>? _sanitizeHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;
    
    final sanitized = <String, dynamic>{};
    
    for (final entry in headers.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      if (_isSensitiveHeader(key)) {
        sanitized[entry.key] = _maskSensitiveValue(value);
      } else {
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized;
  }
  
  /// Sanitize request/response body to remove sensitive information
  static dynamic _sanitizeBody(dynamic body) {
    if (body == null) return null;
    
    if (body is String) {
      return _sanitizeString(body);
    } else if (body is Map<String, dynamic>) {
      return _sanitizeData(body);
    } else if (body is List) {
      return body.map((item) => _sanitizeBody(item)).toList();
    }
    
    return body;
  }
  
  /// Sanitize string content to remove sensitive information
  static String _sanitizeString(String content) {
    // Remove API keys (64-character hex strings)
    content = content.replaceAll(RegExp(r'\b[a-fA-F0-9]{64}\b'), '[API_KEY_MASKED]');
    
    // Remove JWT tokens (base64-like strings with dots)
    content = content.replaceAll(RegExp(r'\b[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'), '[JWT_TOKEN_MASKED]');
    
    // Remove authorization headers
    content = content.replaceAll(RegExp(r'"authorization"\s*:\s*"[^"]*"', caseSensitive: false), '"authorization": "[MASKED]"');
    
    return content;
  }
  
  /// Check if a key is sensitive
  static bool _isSensitiveKey(String key) {
    final sensitiveKeys = [
      'api_key',
      'apikey',
      'token',
      'authorization',
      'password',
      'secret',
      'key',
      'credential',
    ];
    
    return sensitiveKeys.any((sensitiveKey) => key.contains(sensitiveKey));
  }
  
  /// Check if a header is sensitive
  static bool _isSensitiveHeader(String key) {
    final sensitiveHeaders = [
      'authorization',
      'x-api-key',
      'x-auth-token',
      'cookie',
      'set-cookie',
    ];
    
    return sensitiveHeaders.any((sensitiveHeader) => key.contains(sensitiveHeader));
  }
  
  /// Mask sensitive values
  static String _maskSensitiveValue(dynamic value) {
    if (value == null) return '[NULL]';
    
    final stringValue = value.toString();
    
    if (stringValue.isEmpty) return '[EMPTY]';
    
    if (stringValue.length <= 8) {
      return '*' * stringValue.length;
    }
    
    return '${stringValue.substring(0, 4)}${'*' * (stringValue.length - 8)}${stringValue.substring(stringValue.length - 4)}';
  }
}
