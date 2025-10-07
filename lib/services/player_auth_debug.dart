import 'player_auth_service.dart';
import 'secure_logger.dart';

/// Debug utilities for player authentication
class PlayerAuthDebug {
  /// Clear all player authentication data (useful for testing)
  static Future<void> clearAllAuthData() async {
    try {
      SecureLogger.logDebug('PlayerAuthDebug: Clearing all auth data...');
      await PlayerAuthService.clearAuth();
      SecureLogger.logDebug('PlayerAuthDebug: Auth data cleared successfully');
    } catch (e) {
      SecureLogger.logError('PlayerAuthDebug: Failed to clear auth data', error: e);
    }
  }

  /// Check current authentication status
  static Future<void> checkAuthStatus() async {
    try {
      SecureLogger.logDebug('PlayerAuthDebug: Checking auth status...');
      
      final isAuthenticated = await PlayerAuthService.isAuthenticated();
      SecureLogger.logDebug('PlayerAuthDebug: Is authenticated: $isAuthenticated');
      
      final token = await PlayerAuthService.getToken();
      SecureLogger.logDebug('PlayerAuthDebug: Has token: ${token != null}');
      
      if (token != null) {
        final expiration = await PlayerAuthService.getTokenExpiration();
        SecureLogger.logDebug('PlayerAuthDebug: Token expiration: $expiration');
      }
      
      final player = await PlayerAuthService.getCurrentPlayer();
      SecureLogger.logDebug('PlayerAuthDebug: Current player: ${player?.username ?? "none"}');
      
    } catch (e) {
      SecureLogger.logError('PlayerAuthDebug: Error checking auth status', error: e);
    }
  }

  /// Run all debug checks
  static Future<void> runAllChecks() async {
    SecureLogger.logDebug('=== PlayerAuth Debug Checks ===');
    await checkAuthStatus();
    SecureLogger.logDebug('=== End Debug Checks ===');
  }
}
