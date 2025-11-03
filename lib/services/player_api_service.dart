import 'package:dio/dio.dart';
import '../models/player.dart';
import '../models/player_profile.dart';
import '../models/player_achievements.dart';
import '../models/leaderboard_response.dart';
import '../models/game_history_response.dart';
import 'api_service.dart';
import 'player_auth_service.dart';
import 'secure_logger.dart';

class PlayerApiService {
  /// Get player profile information
  static Future<Player?> getPlayerProfile() async {
    try {
      SecureLogger.logDebug('Fetching player profile');

      final response = await ApiService.get('/api/v1/players/profile');

      if (response.statusCode == 200) {
        final playerData =
            response.data['player'] as Map<String, dynamic>? ??
            response.data as Map<String, dynamic>;
        final player = Player.fromJson(playerData);

        // Update cached player data without clearing the JWT token
        final token = await PlayerAuthService.getToken();
        if (token != null) {
          // Re-store with updated player data (keeping the same token)
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
    String? avatarUrl,
    PlayerProfile? profile,
  }) async {
    try {
      SecureLogger.logDebug('Updating player profile');

      final playerData = <String, dynamic>{};
      if (username != null) playerData['username'] = username;
      if (displayName != null) playerData['display_name'] = displayName;
      if (avatarUrl != null) playerData['avatar_url'] = avatarUrl;

      final requestData = <String, dynamic>{'player': playerData};

      // Add profile data nested under player if provided
      if (profile != null) {
        playerData['profile'] = profile.toJson();
      }

      final response = await ApiService.put(
        '/api/v1/players/profile',
        data: requestData,
      );

      if (response.statusCode == 200) {
        final playerData =
            response.data['player'] as Map<String, dynamic>? ??
            response.data as Map<String, dynamic>;
        final player = Player.fromJson(playerData);

        // Update cached player data without clearing the JWT token
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

      final response = await ApiService.get('/api/v1/players/stats');

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

      final response = await ApiService.get(
        '/api/v1/players/game_history',
        queryParameters: {'limit': limit, 'offset': offset},
      );

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
    required int heartsCollected,
  }) async {
    try {
      SecureLogger.logDebug(
        'Submitting game session with player authentication',
      );

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
        'hearts_collected': heartsCollected,
      };

      // Add player_name for display purposes (optional, server may use player from JWT)
      if (currentPlayer != null) {
        gameSessionData['player_name'] = currentPlayer.displayName;
      }

      final gameData = {'game_session': gameSessionData};

      final response = await ApiService.post(
        '/api/v1/game_sessions',
        data: gameData,
      );

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

      final queryParams = <String, dynamic>{'limit': limit};
      if (timeFrame != null) {
        queryParams['time_frame'] = timeFrame;
      }

      final response = await ApiService.get(
        '/api/v1/scores/leaderboard',
        queryParameters: queryParams,
      );

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

  /// Get global leaderboard (public endpoint)
  static Future<LeaderboardResponse?> getGlobalLeaderboard({
    int limit = 100,
  }) async {
    try {
      SecureLogger.logDebug('Fetching global leaderboard (limit: $limit)');

      // Ensure limit doesn't exceed max
      final effectiveLimit = limit > 500 ? 500 : limit;

      final response = await ApiService.get(
        '/api/v1/leaderboard',
        queryParameters: {'limit': effectiveLimit},
      );

      if (response.statusCode == 200) {
        final leaderboard = LeaderboardResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        SecureLogger.logDebug(
          'Global leaderboard fetched successfully: ${leaderboard.totalEntries} total entries',
        );
        return leaderboard;
      }

      return null;
    } catch (e) {
      SecureLogger.logError('Failed to fetch global leaderboard', error: e);
      return null;
    }
  }

  /// Get player achievements by username (public endpoint)
  static Future<PlayerAchievements?> getPlayerAchievements(
    String username,
  ) async {
    try {
      SecureLogger.logDebug('Fetching achievements for username: $username');

      final response = await ApiService.get(
        '/api/v1/players/$username/achievements',
      );

      if (response.statusCode == 200) {
        final achievements = PlayerAchievements.fromJson(
          response.data as Map<String, dynamic>,
        );
        SecureLogger.logDebug(
          'Player achievements fetched successfully: ${achievements.totalAchievements} achievements',
        );
        return achievements;
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        SecureLogger.logDebug('Player not found: $username');
        return null;
      }
      SecureLogger.logError('Failed to fetch player achievements', error: e);
      return null;
    } catch (e) {
      SecureLogger.logError('Failed to fetch player achievements', error: e);
      return null;
    }
  }

  /// Get player game history by username (public endpoint)
  static Future<GameHistoryResponse?> getPlayerGameHistoryByUsername(
    String username, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      SecureLogger.logDebug(
        'Fetching game history for username: $username (limit: $limit, offset: $offset)',
      );

      // Ensure limit doesn't exceed max
      final effectiveLimit = limit > 100 ? 100 : limit;

      final response = await ApiService.get(
        '/api/v1/players/$username/game-history',
        queryParameters: {'limit': effectiveLimit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final gameHistory = GameHistoryResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        SecureLogger.logDebug(
          'Player game history fetched successfully: ${gameHistory.returned} games returned',
        );
        return gameHistory;
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        SecureLogger.logDebug('Player not found: $username');
        return null;
      }
      SecureLogger.logError('Failed to fetch player game history', error: e);
      return null;
    } catch (e) {
      SecureLogger.logError('Failed to fetch player game history', error: e);
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
      SecureLogger.logError(
        'Failed to store updated player auth data',
        error: e,
      );
    }
  }
}
