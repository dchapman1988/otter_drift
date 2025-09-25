import 'package:dio/dio.dart';
import 'api_service.dart';
import 'auth_service.dart';

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
  }) async {
    try {
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
}


