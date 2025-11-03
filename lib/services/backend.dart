import 'package:dio/dio.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'player_auth_service.dart';
import 'player_api_service.dart';
import '../models/player.dart';
import '../models/player_profile.dart';
import '../models/leaderboard_response.dart';

class BackendService {

  static Future<Map<String, dynamic>?> saveScore({
    required String sessionId,
    required String playerName,
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
      // Check if player is authenticated and use player API service
      if (await PlayerAuthService.isAuthenticated()) {
        return await PlayerApiService.submitGameSession(
          sessionId: sessionId,
          seed: seed,
          startedAt: startedAt,
          endedAt: endedAt,
          finalScore: finalScore,
          gameDuration: gameDuration,
          maxSpeedReached: maxSpeedReached,
          obstaclesAvoided: obstaclesAvoided,
          liliesCollected: liliesCollected,
          heartsCollected: heartsCollected,
        );
      }

      // Fallback to original system for guest mode
      final response = await ApiService.post('/api/v1/game_sessions', data: {
        'game_session': {
          'session_id': sessionId,
          'player_name': playerName,
          'seed': seed,
          'started_at': startedAt.toIso8601String(),
          'ended_at': endedAt.toIso8601String(),
          'final_score': finalScore,
          'game_duration': gameDuration,
          'max_speed_reached': maxSpeedReached,
          'obstacles_avoided': obstaclesAvoided,
          'lilies_collected': liliesCollected,
          'hearts_collected': heartsCollected,
        }
      });
      
      print('POST /api/v1/game_sessions - Status: ${response.statusCode}');
      print('Response: ${response.data}');
      
      return response.data;
    } catch (e) {
      print('POST /api/v1/game_sessions - Error: $e');
      if (e is DioException) {
        print('Status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
      }
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> topScores({int limit = 10}) async {
    try {
      final response = await ApiService.get('/api/v1/scores/top', queryParameters: {
        'limit': limit,
      });
      
      print('GET /api/v1/scores/top - Status: ${response.statusCode}');
      print('Response: ${response.data}');
      
      if (response.data is Map && response.data.containsKey('scores')) {
        return List<Map<String, dynamic>>.from(response.data['scores']);
      }
      return [];
    } catch (e) {
      print('GET /api/v1/scores/top - Error: $e');
      if (e is DioException) {
        print('Status code: ${e.response?.statusCode}');
        print('Response data: ${e.response?.data}');
      }
      return null;
    }
  }

  static Future<bool> checkConnection() async {
    return await ApiService.checkConnection();
  }

  /// Check if the user is authenticated
  static Future<bool> isAuthenticated() async {
    return await AuthService.isAuthenticated();
  }

  /// Authenticate with the backend
  static Future<bool> authenticate() async {
    return await AuthService.authenticate();
  }

  /// Clear authentication token
  static Future<void> logout() async {
    await AuthService.clearToken();
  }

  /// Test authentication endpoint
  static Future<bool> testAuthentication() async {
    return await ApiService.testAuthentication();
  }

  // Player Authentication Methods

  /// Check if player is authenticated
  static Future<bool> isPlayerAuthenticated() async {
    return await PlayerAuthService.isAuthenticated();
  }

  /// Get current player
  static Future<Player?> getCurrentPlayer() async {
    return await PlayerAuthService.getCurrentPlayer();
  }

  /// Sign up a new player
  static Future<AuthResult> signUpPlayer({
    required String email,
    required String username,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await PlayerAuthService.signUp(
      email: email,
      username: username,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  /// Sign in a player
  static Future<AuthResult> signInPlayer({
    required String email,
    required String password,
  }) async {
    return await PlayerAuthService.signIn(
      email: email,
      password: password,
    );
  }

  /// Sign out the current player
  static Future<bool> signOutPlayer() async {
    return await PlayerAuthService.signOut();
  }

  /// Get player profile
  static Future<Player?> getPlayerProfile() async {
    return await PlayerApiService.getPlayerProfile();
  }

  /// Update player profile
  static Future<Player?> updatePlayerProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    PlayerProfile? profile,
  }) async {
    return await PlayerApiService.updatePlayerProfile(
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      profile: profile,
    );
  }

  /// Get player statistics
  static Future<Map<String, dynamic>?> getPlayerStats() async {
    return await PlayerApiService.getPlayerStats();
  }

  /// Get player's game history
  static Future<List<Map<String, dynamic>>?> getPlayerGameHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    return await PlayerApiService.getPlayerGameHistory(
      limit: limit,
      offset: offset,
    );
  }

  /// Get leaderboard with player's position (legacy endpoint)
  static Future<Map<String, dynamic>?> getLeaderboard({
    int limit = 10,
    String? timeFrame,
  }) async {
    return await PlayerApiService.getLeaderboard(
      limit: limit,
      timeFrame: timeFrame,
    );
  }

  /// Get global leaderboard (new endpoint)
  static Future<LeaderboardResponse?> getGlobalLeaderboard({
    int limit = 100,
  }) async {
    return await PlayerApiService.getGlobalLeaderboard(limit: limit);
  }
}


