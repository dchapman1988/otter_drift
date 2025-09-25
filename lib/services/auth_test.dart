import 'package:flutter_test/flutter_test.dart';
import 'auth_service.dart';
import 'config.dart';

/// Simple test to verify authentication service functionality
class AuthTest {
  
  /// Test configuration values
  static void testConfiguration() {
    print('Testing configuration...');
    
    final baseUrlValue = baseUrl();
    final clientIdValue = clientId();
    final apiKeyValue = apiKey();
    
    print('Base URL: $baseUrlValue');
    print('Client ID: $clientIdValue');
    print('API Key: $apiKeyValue');
    
    // Verify default values
    assert(clientIdValue == 'game_client_1', 'Default client ID should be game_client_1');
    assert(apiKeyValue == 'your_secret_key_here', 'Default API key should be your_secret_key_here');
    
    print('Configuration test passed ✓');
  }
  
  /// Test token storage and retrieval
  static Future<void> testTokenStorage() async {
    print('Testing token storage...');
    
    // Clear any existing token
    await AuthService.clearToken();
    
    // Verify no token exists
    final tokenBefore = await AuthService.getToken();
    assert(tokenBefore == null, 'Token should be null after clearing');
    
    // Verify not authenticated
    final isAuthBefore = await AuthService.isAuthenticated();
    assert(isAuthBefore == false, 'Should not be authenticated after clearing token');
    
    print('Token storage test passed ✓');
  }
  
  /// Test token expiration logic
  static Future<void> testTokenExpiration() async {
    print('Testing token expiration logic...');
    
    // Test with expired token (this is a mock test since we don't have a real token)
    final expiration = await AuthService.getTokenExpiration();
    assert(expiration == null, 'Expiration should be null when no token exists');
    
    final isExpiringSoon = await AuthService.isTokenExpiringSoon();
    assert(isExpiringSoon == true, 'Should return true when no token exists');
    
    print('Token expiration test passed ✓');
  }
  
  /// Run all tests
  static Future<void> runAllTests() async {
    print('=== Running Authentication Tests ===\n');
    
    try {
      testConfiguration();
      print('');
      
      await testTokenStorage();
      print('');
      
      await testTokenExpiration();
      print('');
      
      print('=== All Tests Passed! ===');
    } catch (e) {
      print('=== Test Failed: $e ===');
      rethrow;
    }
  }
}
