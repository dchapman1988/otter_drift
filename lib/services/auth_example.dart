import 'backend.dart';
import 'auth_service.dart';
import 'security_config.dart';
import 'secure_logger.dart';

/// Example usage of the JWT authentication system
class AuthExample {
  
  /// Example: Initialize authentication when the app starts
  static Future<void> initializeAuth() async {
    SecureLogger.logInfo('Initializing authentication system');
    
    // Validate security configuration
    try {
      SecurityConfig.validateConfiguration();
      SecureLogger.logInfo('Security configuration validated successfully');
    } catch (e) {
      SecureLogger.logError('Security configuration validation failed', error: e);
      rethrow;
    }
    
    // Check if already authenticated
    final isAuth = await BackendService.isAuthenticated();
    if (isAuth) {
      SecureLogger.logInfo('Already authenticated');
      return;
    }
    
    // Authenticate if not already authenticated
    final authSuccess = await BackendService.authenticate();
    if (authSuccess) {
      SecureLogger.logInfo('Authentication successful');
    } else {
      SecureLogger.logError('Authentication failed');
    }
  }

  /// Example: Save a game score with automatic authentication
  static Future<void> saveGameScore() async {
    print('Saving game score...');
    
    // The saveScore method will automatically handle authentication
    // No need to manually check or authenticate
    final result = await BackendService.saveScore(
      sessionId: 'session_123',
      playerName: 'Player1',
      seed: 42,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      endedAt: DateTime.now(),
      finalScore: 1500,
      gameDuration: 300.0,
      maxSpeedReached: 15.5,
      obstaclesAvoided: 12,
      liliesCollected: 8,
    );
    
    if (result != null) {
      print('Score saved successfully: $result');
    } else {
      print('Failed to save score');
    }
  }

  /// Example: Get top scores with automatic authentication
  static Future<void> getTopScores() async {
    print('Getting top scores...');
    
    final scores = await BackendService.topScores(limit: 5);
    if (scores != null) {
      print('Top scores: $scores');
    } else {
      print('Failed to get top scores');
    }
  }

  /// Example: Check authentication status
  static Future<void> checkAuthStatus() async {
    final isAuth = await BackendService.isAuthenticated();
    SecureLogger.logInfo('Authentication status: $isAuth');
    
    if (isAuth) {
      final tokenExpiration = await AuthService.getTokenExpiration();
      SecureLogger.logInfo('Token expires at: $tokenExpiration');
      
      final isExpiringSoon = await AuthService.isTokenExpiringSoon();
      SecureLogger.logInfo('Token expiring soon: $isExpiringSoon');
    }
    
    // Show environment info in debug mode
    if (SecurityConfig.isDebugMode()) {
      final envInfo = SecurityConfig.getEnvironmentInfo();
      SecureLogger.logDebug('Environment information', data: envInfo);
    }
  }

  /// Example: Manual logout
  static Future<void> logout() async {
    print('Logging out...');
    await BackendService.logout();
    print('Logged out successfully');
  }

  /// Example: Test authentication endpoint
  static Future<void> testAuth() async {
    print('Testing authentication endpoint...');
    final success = await BackendService.testAuthentication();
    print('Authentication test result: $success');
  }

  /// Example: Complete workflow
  static Future<void> runCompleteExample() async {
    print('=== JWT Authentication Example ===\n');
    
    // 1. Initialize authentication
    await initializeAuth();
    print('');
    
    // 2. Check authentication status
    await checkAuthStatus();
    print('');
    
    // 3. Test authentication endpoint
    await testAuth();
    print('');
    
    // 4. Save a game score (will use authentication automatically)
    await saveGameScore();
    print('');
    
    // 5. Get top scores (will use authentication automatically)
    await getTopScores();
    print('');
    
    // 6. Check status again
    await checkAuthStatus();
    print('');
    
    // 7. Logout
    await logout();
    print('');
    
    // 8. Check status after logout
    await checkAuthStatus();
    print('');
    
    print('=== Example Complete ===');
  }
}
