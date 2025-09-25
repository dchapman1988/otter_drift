import 'security_config.dart';
import 'secure_logger.dart';

/// Quick test to verify the security configuration works
class QuickTest {
  
  /// Test the security configuration
  static void testSecurityConfig() {
    try {
      SecureLogger.logInfo('🧪 Testing Security Configuration...');
      
      // Test configuration validation
      SecurityConfig.validateConfiguration();
      SecureLogger.logInfo('✅ Configuration validation passed');
      
      // Show environment info
      final envInfo = SecurityConfig.getEnvironmentInfo();
      SecureLogger.logInfo('Environment info', data: envInfo);
      
      // Show masked API key
      final maskedApiKey = SecurityConfig.getMaskedApiKey();
      SecureLogger.logInfo('API Key (masked): $maskedApiKey');
      
      SecureLogger.logInfo('🎉 All security tests passed!');
      
    } catch (e) {
      SecureLogger.logError('❌ Security test failed', error: e);
      rethrow;
    }
  }
}
