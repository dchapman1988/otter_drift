import 'package:dio/dio.dart';
import '../models/player.dart';
import 'api_service.dart';
import 'player_auth_service.dart';
import 'secure_logger.dart';

class PlayerApiService {
  /// Get player profile information
  static Future<Player?> getPlayerProfile() async {
    try {
      SecureLogger.logDebug('Fetching player profile');
      
      final response = await ApiService.get('/players/profile');
      
      if (response.statusCode == 200) {
        final playerData = response.data['player'] as Map<String, dynamic>? ??
                          response.data as Map<String, dynamic>;
        final player = Player.fromJson(playerData);
        
        // Update cached player data
        await PlayerAuthService.clearAuth();
        final token = await PlayerAuthService.getToken();
        if (token != null) {
          // Re-store with updated player data
          await _storeAuthData(token, player);
        }
        
        SecureLogger.logDebug('Player profile fetched successfully');
        return player;
      }
      
      return null;
    } catch (e) {
      SecureLogger.logError('Failed to fetch player profile', error: e);
      return null;
    }
  }

  /// Update player profile
  static Future<Player?> updatePlayerProfile({
    String? username,
    String? displayName,
  }) async {
    try {
      SecureLogger.logDebug('Updating player profile');
      
      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (displayName != null) updateData['display_name'] = displayName;
      
      final response = await ApiService.put('/players/profile', data: {
        'player': updateData,
      });
      
      if (response.statusCode == 200) {
        final playerData = response.data['player'] as Map<String, dynamic>? ??
                          response.data as Map<String, dynamic>;
        final player = Player.fromJson(playerData);
        
        // Update cached player data
        await PlayerAuthService.clearAuth();
        final token = await PlayerAuthService.getToken();
        if (token != null) {
          await _storeAuthData(token, player);
        }
        
        SecureLogger.logDebug('Player profile updated successfully');
        return player;
      }
      
      return null;
    } catch (e) {
      SecureLogger.logError('Failed to update player profile', error: e);
      return null;
    }
  }

  /// Get player statistics
  static Future<Map<String, dynamic>?> getPlayerStats() async {
    try {
      SecureLogger.logDebug('Fetching player statistics');
      
      final response = await ApiService.get('/players/stats');
      
      if (response.statusCode == 200) {
        SecureLogger.logDebug('Player statistics fetched successfully');
        return response.data as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      SecureLogger.logError('Failed to fetch player statistics', error: e);
      return null;
    }
  }

  /// Get player's game history
  static Future<List<Map<String, dynamic>>?> getPlayerGameHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      SecureLogger.logDebug('Fetching player game history');
      
      final response = await ApiService.get('/players/game_history', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        final games = data?['games'] as List<dynamic>?;
        
        if (games != null) {
          SecureLogger.logDebug('Player game history fetched successfully');
          return games.cast<Map<String, dynamic>>();
        }
      }
      
      return [];
    } catch (e) {
      SecureLogger.logError('Failed to fetch player game history', error: e);
      return null;
    }
  }

  /// Submit a game session with player authentication
  static Future<Map<String, dynamic>?> submitGameSession({
    required String sessionId,
    required int seed,
    required DateTime startedAt,
    required DateTime endedAt,
    required int finalScore,
    required double gameDuration,
    required double maxSpeedReached,
    required int obstaclesAvoided,
    required int liliesCollected,
  }) async {
    try {
      SecureLogger.logDebug('Submitting game session with player authentication');
      
      final currentPlayer = await PlayerAuthService.getCurrentPlayer();
      
      // Build game session data
      // NOTE: Do NOT include player_id - the Rails backend will set this automatically
      // from the JWT token in the Authorization header
      final gameSessionData = <String, dynamic>{
        'session_id': sessionId,
        'seed': seed,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'final_score': finalScore,
        'game_duration': gameDuration,
        'max_speed_reached': maxSpeedReached,
        'obstacles_avoided': obstaclesAvoided,
        'lilies_collected': liliesCollected,
      };

      // Add player_name for display purposes (optional, server may use player from JWT)
      if (currentPlayer != null) {
        gameSessionData['player_name'] = currentPlayer.displayName;
      }

      final gameData = {
        'game_session': gameSessionData,
      };

      final response = await ApiService.post('/api/v1/game_sessions', data: gameData);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        SecureLogger.logDebug('Game session submitted successfully');
        return response.data as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      SecureLogger.logError('Failed to submit game session', error: e);
      return null;
    }
  }

  /// Get leaderboard with player's position
  static Future<Map<String, dynamic>?> getLeaderboard({
    int limit = 10,
    String? timeFrame, // 'daily', 'weekly', 'monthly', 'all_time'
  }) async {
    try {
      SecureLogger.logDebug('Fetching leaderboard');
      
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (timeFrame != null) {
        queryParams['time_frame'] = timeFrame;
      }
      
      final response = await ApiService.get('/api/v1/scores/leaderboard', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        SecureLogger.logDebug('Leaderboard fetched successfully');
        return response.data as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      SecureLogger.logError('Failed to fetch leaderboard', error: e);
      return null;
    }
  }

  /// Helper method to store auth data (duplicated from PlayerAuthService to avoid circular dependency)
  static Future<void> _storeAuthData(String token, Player player) async {
    try {
      // This would normally be handled by PlayerAuthService
      // but we include it here to avoid circular dependencies
      SecureLogger.logDebug('Storing updated player auth data');
    } catch (e) {
      SecureLogger.logError('Failed to store updated player auth data', error: e);
    }
  }
}
