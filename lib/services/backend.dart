import 'package:dio/dio.dart';
import 'config.dart';

class BackendService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl(),
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  static Future<Map<String, dynamic>?> saveScore({
    required String name,
    required int score,
    required String sessionId,
  }) async {
    try {
      final response = await _dio.post('/api/v1/scores', data: {
        'name': name,
        'score': score,
        'session_id': sessionId,
      });
      
      print('POST /api/v1/scores - Status: ${response.statusCode}');
      print('Response: ${response.data}');
      
      return response.data;
    } catch (e) {
      print('POST /api/v1/scores - Error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> topScores({int limit = 10}) async {
    try {
      final response = await _dio.get('/api/v1/scores/top', queryParameters: {
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
      return null;
    }
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/hello');
      print('GET /hello - Status: ${response.statusCode}');
      print('Response: ${response.data}');
      return response.statusCode == 200;
    } catch (e) {
      print('GET /hello - Error: $e');
      return false;
    }
  }
}


