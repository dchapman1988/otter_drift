import 'player_auth_service.dart';
import 'backend.dart';
import 'secure_logger.dart';

class AuthTest {
  static Future<void> runAuthTests() async {
    SecureLogger.logDebug('Starting authentication tests');
    
    try {
      // Test 1: Check initial authentication state
      final isInitiallyAuthenticated = await BackendService.isPlayerAuthenticated();
      SecureLogger.logDebug('Initial authentication state: $isInitiallyAuthenticated');
      
      // Test 2: Test sign up (this will fail in test environment, but we can test the flow)
      SecureLogger.logDebug('Testing sign up flow...');
      final signUpResult = await BackendService.signUpPlayer(
        email: 'test@example.com',
        username: 'testuser',
        password: 'password123',
        passwordConfirmation: 'password123',
      );
      SecureLogger.logDebug('Sign up result: ${signUpResult.isSuccess}');
      if (!signUpResult.isSuccess) {
        SecureLogger.logDebug('Sign up error: ${signUpResult.message}');
      }
      
      // Test 3: Test sign in (this will also fail in test environment)
      SecureLogger.logDebug('Testing sign in flow...');
      final signInResult = await BackendService.signInPlayer(
        email: 'test@example.com',
        password: 'password123',
      );
      SecureLogger.logDebug('Sign in result: ${signInResult.isSuccess}');
      if (!signInResult.isSuccess) {
        SecureLogger.logDebug('Sign in error: ${signInResult.message}');
      }
      
      // Test 4: Test guest mode
      SecureLogger.logDebug('Testing guest mode...');
      // Guest mode is handled by the UI, but we can test the backend service
      final guestPlayer = await BackendService.getCurrentPlayer();
      SecureLogger.logDebug('Current player (should be null for guest): $guestPlayer');
      
      // Test 5: Test token management
      SecureLogger.logDebug('Testing token management...');
      final hasToken = await PlayerAuthService.getToken();
      SecureLogger.logDebug('Has token: ${hasToken != null}');
      
      if (hasToken != null) {
        final isExpired = await PlayerAuthService.isTokenExpiringSoon();
        SecureLogger.logDebug('Token expiring soon: $isExpired');
        
        final expiration = await PlayerAuthService.getTokenExpiration();
        SecureLogger.logDebug('Token expiration: $expiration');
      }
      
      SecureLogger.logDebug('Authentication tests completed');
      
    } catch (e) {
      SecureLogger.logError('Authentication test failed', error: e);
    }
  }
  
  static Future<void> testGameSessionSubmission() async {
    SecureLogger.logDebug('Testing game session submission...');
    
    try {
      // Test game session submission (this will work in guest mode)
      final result = await BackendService.saveScore(
        sessionId: 'test-session-123',
        playerName: 'Test Player',
        seed: 12345,
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        endedAt: DateTime.now(),
        finalScore: 1000,
        gameDuration: 300.0,
        maxSpeedReached: 150.0,
        obstaclesAvoided: 10,
        liliesCollected: 5,
      );
      
      if (result != null) {
        SecureLogger.logDebug('Game session submitted successfully');
      } else {
        SecureLogger.logDebug('Game session submission failed');
      }
      
    } catch (e) {
      SecureLogger.logError('Game session test failed', error: e);
    }
  }
}