import 'dart:io';

/// Security configuration class that validates and manages authentication credentials
class SecurityConfig {
  static const String _defaultClientId = 'game_client_1';
  static const int _expectedApiKeyLength = 64; // 64-character hex string
  
  // Build-time configuration
  static const String? _envApiKey = String.fromEnvironment('API_KEY');
  static const String? _envClientId = String.fromEnvironment('CLIENT_ID');
  static const String? _envBaseUrl = String.fromEnvironment('API_BASE');
  static const bool _isDebugMode = bool.fromEnvironment('dart.vm.product') == false;
  
  // Certificate pins for different environments
  static const Map<String, List<String>> _certificatePins = {
    'localhost:3000': [
      // Add your localhost certificate pin here
      // You can get this by running: openssl s_client -connect localhost:3000 -servername localhost
      'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Placeholder - replace with actual pin
    ],
    'your-production-domain.com': [
      // Add your production certificate pins here
      'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Placeholder - replace with actual pin
    ],
  };

  /// Get the client ID with validation
  static String getClientId() {
    final clientId = _envClientId ?? _defaultClientId;
    _validateClientId(clientId);
    return clientId;
  }

  /// Get the API key with validation
  static String getApiKey() {
    if (_envApiKey == null || _envApiKey!.isEmpty) {
      throw SecurityException(
        'API_KEY environment variable is required. '
        'Use --dart-define=API_KEY=your_api_key_here when building.'
      );
    }
    
    _validateApiKey(_envApiKey!);
    return _envApiKey!;
  }

  /// Get the base URL with validation
  static String getBaseUrl() {
    if (_envBaseUrl != null && _envBaseUrl!.isNotEmpty) {
      return _envBaseUrl!;
    }
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Check if running in debug mode
  static bool isDebugMode() => _isDebugMode;

  /// Get certificate pins for the given host
  static List<String> getCertificatePins(String host) {
    return _certificatePins[host] ?? [];
  }

  /// Validate client ID format
  static void _validateClientId(String clientId) {
    if (clientId.isEmpty) {
      throw SecurityException('Client ID cannot be empty');
    }
    
    if (clientId.length < 3) {
      throw SecurityException('Client ID must be at least 3 characters long');
    }
    
    // Allow alphanumeric, underscore, and hyphen
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clientId)) {
      throw SecurityException('Client ID can only contain alphanumeric characters, underscores, and hyphens');
    }
  }

  /// Validate API key format
  static void _validateApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      throw SecurityException('API key cannot be empty');
    }
    
    if (apiKey.length != _expectedApiKeyLength) {
      throw SecurityException(
        'API key must be exactly $_expectedApiKeyLength characters long. '
        'Received: ${apiKey.length} characters'
      );
    }
    
    // Validate hex format
    if (!RegExp(r'^[a-fA-F0-9]+$').hasMatch(apiKey)) {
      throw SecurityException('API key must be a valid hexadecimal string');
    }
  }

  /// Get a masked version of the API key for logging (shows first 8 and last 4 characters)
  static String getMaskedApiKey() {
    try {
      final apiKey = getApiKey();
      if (apiKey.length <= 12) {
        return '*' * apiKey.length;
      }
      return '${apiKey.substring(0, 8)}${'*' * (apiKey.length - 12)}${apiKey.substring(apiKey.length - 4)}';
    } catch (e) {
      return '***MISSING***';
    }
  }

  /// Get environment information for debugging
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'isDebugMode': isDebugMode(),
      'clientId': getClientId(),
      'maskedApiKey': getMaskedApiKey(),
      'baseUrl': getBaseUrl(),
      'hasApiKey': _envApiKey != null && _envApiKey!.isNotEmpty,
      'hasClientId': _envClientId != null && _envClientId!.isNotEmpty,
      'hasBaseUrl': _envBaseUrl != null && _envBaseUrl!.isNotEmpty,
    };
  }

  /// Validate all configuration at startup
  static void validateConfiguration() {
    try {
      getClientId();
      getApiKey();
      getBaseUrl();
      
      if (isDebugMode()) {
        print('🔧 SecurityConfig: Configuration validated successfully');
        print('🔧 Environment Info: ${getEnvironmentInfo()}');
      }
    } catch (e) {
      print('❌ SecurityConfig: Configuration validation failed: $e');
      rethrow;
    }
  }

  /// Get retry configuration
  static RetryConfig getRetryConfig() {
    return RetryConfig(
      maxAttempts: 3,
      baseDelay: const Duration(seconds: 1),
      maxDelay: const Duration(seconds: 10),
      backoffMultiplier: 2.0,
    );
  }

  /// Get timeout configuration
  static TimeoutConfig getTimeoutConfig() {
    return TimeoutConfig(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
    );
  }
}

/// Retry configuration for network requests
class RetryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryConfig({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
  });
}

/// Timeout configuration for network requests
class TimeoutConfig {
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  const TimeoutConfig({
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
  });
}

/// Security exception for configuration errors
class SecurityException implements Exception {
  final String message;
  
  const SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
