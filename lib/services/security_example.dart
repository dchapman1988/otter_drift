import 'backend.dart';
import 'auth_service.dart';
import 'security_config.dart';
import 'secure_logger.dart';
import 'certificate_pinning_service.dart';

/// Comprehensive example demonstrating all security features
class SecurityExample {
  
  /// Example: Complete security setup and testing
  static Future<void> runSecurityDemo() async {
    SecureLogger.logInfo('🔒 Starting Security Demo');
    
    try {
      // 1. Validate security configuration
      await _validateSecurityConfig();
      
      // 2. Test certificate pinning (if configured)
      await _testCertificatePinning();
      
      // 3. Test authentication with retry logic
      await _testAuthentication();
      
      // 4. Test API calls with automatic authentication
      await _testApiCalls();
      
      // 5. Test error handling and re-authentication
      await _testErrorHandling();
      
      SecureLogger.logInfo('✅ Security Demo completed successfully');
      
    } catch (e) {
      SecureLogger.logError('❌ Security Demo failed', error: e);
      rethrow;
    }
  }
  
  /// Validate security configuration
  static Future<void> _validateSecurityConfig() async {
    SecureLogger.logInfo('🔧 Validating security configuration...');
    
    try {
      SecurityConfig.validateConfiguration();
      
      final envInfo = SecurityConfig.getEnvironmentInfo();
      SecureLogger.logInfo('Security configuration valid', data: envInfo);
      
      // Show masked API key for verification
      final maskedApiKey = SecurityConfig.getMaskedApiKey();
      SecureLogger.logInfo('API Key (masked): $maskedApiKey');
      
    } catch (e) {
      SecureLogger.logError('Security configuration validation failed', error: e);
      rethrow;
    }
  }
  
  /// Test certificate pinning
  static Future<void> _testCertificatePinning() async {
    SecureLogger.logInfo('🔐 Testing certificate pinning...');
    
    try {
      final baseUrl = SecurityConfig.getBaseUrl();
      final uri = Uri.parse(baseUrl);
      final host = '${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      
      final pins = SecurityConfig.getCertificatePins(host);
      
      if (pins.isEmpty) {
        SecureLogger.logInfo('No certificate pins configured for $host');
        return;
      }
      
      SecureLogger.logInfo('Certificate pins configured for $host', data: {'pins': pins});
      
      // Test certificate pinning
      final success = await CertificatePinningService.testCertificatePinning(host);
      
      if (success) {
        SecureLogger.logInfo('✅ Certificate pinning test passed');
      } else {
        SecureLogger.logError('❌ Certificate pinning test failed');
      }
      
    } catch (e) {
      SecureLogger.logError('Certificate pinning test error', error: e);
    }
  }
  
  /// Test authentication with retry logic
  static Future<void> _testAuthentication() async {
    SecureLogger.logInfo('🔑 Testing authentication...');
    
    try {
      // Clear any existing token
      await AuthService.clearToken();
      
      // Test authentication
      final authSuccess = await BackendService.authenticate();
      
      if (authSuccess) {
        SecureLogger.logInfo('✅ Authentication successful');
        
        // Check token details
        final isAuth = await BackendService.isAuthenticated();
        final tokenExpiration = await AuthService.getTokenExpiration();
        final isExpiringSoon = await AuthService.isTokenExpiringSoon();
        
        SecureLogger.logInfo('Token details', data: {
          'isAuthenticated': isAuth,
          'expiration': tokenExpiration?.toIso8601String(),
          'expiringSoon': isExpiringSoon,
        });
        
      } else {
        SecureLogger.logError('❌ Authentication failed');
      }
      
    } catch (e) {
      SecureLogger.logError('Authentication test error', error: e);
    }
  }
  
  /// Test API calls with automatic authentication
  static Future<void> _testApiCalls() async {
    SecureLogger.logInfo('🌐 Testing API calls...');
    
    try {
      // Test connection check
      final connectionOk = await BackendService.checkConnection();
      SecureLogger.logInfo('Connection check: $connectionOk');
      
      // Test authentication endpoint
      final authTestOk = await BackendService.testAuthentication();
      SecureLogger.logInfo('Authentication endpoint test: $authTestOk');
      
      // Test saving a score (this will use automatic authentication)
      final scoreResult = await BackendService.saveScore(
        sessionId: 'security_test_${DateTime.now().millisecondsSinceEpoch}',
        playerName: 'SecurityTester',
        seed: 12345,
        startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        endedAt: DateTime.now(),
        finalScore: 9999,
        gameDuration: 120.0,
        maxSpeedReached: 20.0,
        obstaclesAvoided: 15,
        liliesCollected: 10,
      );
      
      if (scoreResult != null) {
        SecureLogger.logInfo('✅ Score saved successfully', data: scoreResult);
      } else {
        SecureLogger.logError('❌ Failed to save score');
      }
      
      // Test getting top scores
      final topScores = await BackendService.topScores(limit: 3);
      if (topScores != null) {
        SecureLogger.logInfo('✅ Top scores retrieved', data: {'count': topScores.length});
      } else {
        SecureLogger.logError('❌ Failed to get top scores');
      }
      
    } catch (e) {
      SecureLogger.logError('API calls test error', error: e);
    }
  }
  
  /// Test error handling and re-authentication
  static Future<void> _testErrorHandling() async {
    SecureLogger.logInfo('🔄 Testing error handling...');
    
    try {
      // Test with invalid token (simulate token expiration)
      await AuthService.clearToken();
      
      // This should trigger automatic re-authentication
      final connectionOk = await BackendService.checkConnection();
      SecureLogger.logInfo('Connection after token clear: $connectionOk');
      
      // Test re-authentication
      final reAuthSuccess = await AuthService.reAuthenticate();
      SecureLogger.logInfo('Re-authentication: $reAuthSuccess');
      
    } catch (e) {
      SecureLogger.logError('Error handling test error', error: e);
    }
  }
  
  /// Example: Production-ready initialization
  static Future<void> initializeForProduction() async {
    SecureLogger.logInfo('🚀 Initializing for production...');
    
    try {
      // Validate configuration (will fail if API key is missing)
      SecurityConfig.validateConfiguration();
      
      // Test authentication
      final authSuccess = await BackendService.authenticate();
      if (!authSuccess) {
        throw Exception('Initial authentication failed');
      }
      
      // Test certificate pinning if configured
      final baseUrl = SecurityConfig.getBaseUrl();
      if (baseUrl.startsWith('https://')) {
        final uri = Uri.parse(baseUrl);
        final host = '${uri.host}${uri.port != 443 ? ':${uri.port}' : ''}';
        final pins = SecurityConfig.getCertificatePins(host);
        
        if (pins.isNotEmpty) {
          final pinningSuccess = await CertificatePinningService.testCertificatePinning(host);
          if (!pinningSuccess) {
            throw Exception('Certificate pinning test failed');
          }
        }
      }
      
      SecureLogger.logInfo('✅ Production initialization completed successfully');
      
    } catch (e) {
      SecureLogger.logError('❌ Production initialization failed', error: e);
      rethrow;
    }
  }
  
  /// Example: Debug mode testing
  static Future<void> runDebugTests() async {
    if (!SecurityConfig.isDebugMode()) {
      SecureLogger.logInfo('Debug tests only available in debug mode');
      return;
    }
    
    SecureLogger.logInfo('🐛 Running debug tests...');
    
    try {
      // Show environment information
      final envInfo = SecurityConfig.getEnvironmentInfo();
      SecureLogger.logDebug('Environment info', data: envInfo);
      
      // Test configuration validation
      SecurityConfig.validateConfiguration();
      SecureLogger.logDebug('Configuration validation passed');
      
      // Test retry configuration
      final retryConfig = SecurityConfig.getRetryConfig();
      SecureLogger.logDebug('Retry configuration', data: {
        'maxAttempts': retryConfig.maxAttempts,
        'baseDelay': retryConfig.baseDelay.inMilliseconds,
        'maxDelay': retryConfig.maxDelay.inMilliseconds,
        'backoffMultiplier': retryConfig.backoffMultiplier,
      });
      
      // Test timeout configuration
      final timeoutConfig = SecurityConfig.getTimeoutConfig();
      SecureLogger.logDebug('Timeout configuration', data: {
        'connectTimeout': timeoutConfig.connectTimeout.inSeconds,
        'receiveTimeout': timeoutConfig.receiveTimeout.inSeconds,
        'sendTimeout': timeoutConfig.sendTimeout.inSeconds,
      });
      
      SecureLogger.logInfo('✅ Debug tests completed');
      
    } catch (e) {
      SecureLogger.logError('❌ Debug tests failed', error: e);
    }
  }
}
