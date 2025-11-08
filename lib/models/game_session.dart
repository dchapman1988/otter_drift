import 'dart:convert';

class GameSession {
  GameSession({
    required this.sessionId,
    required this.playerName,
    required this.seed,
    required this.startedAt,
    required this.endedAt,
    required this.finalScore,
    required this.gameDuration,
    required this.maxSpeedReached,
    required this.obstaclesAvoided,
    required this.liliesCollected,
    required this.heartsCollected,
  });

  final String sessionId;
  final String playerName;
  final int seed;
  final DateTime startedAt;
  final DateTime endedAt;
  final int finalScore;
  final double gameDuration;
  final double maxSpeedReached;
  final int obstaclesAvoided;
  final int liliesCollected;
  final int heartsCollected;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'playerName': playerName,
      'seed': seed,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'finalScore': finalScore,
      'gameDuration': gameDuration,
      'maxSpeedReached': maxSpeedReached,
      'obstaclesAvoided': obstaclesAvoided,
      'liliesCollected': liliesCollected,
      'heartsCollected': heartsCollected,
    };
  }

  static GameSession fromJson(Map<String, dynamic> json) {
    return GameSession(
      sessionId: json['sessionId'] as String,
      playerName: json['playerName'] as String? ?? 'Guest Player',
      seed: json['seed'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      finalScore: json['finalScore'] as int,
      gameDuration: (json['gameDuration'] as num).toDouble(),
      maxSpeedReached: (json['maxSpeedReached'] as num).toDouble(),
      obstaclesAvoided: json['obstaclesAvoided'] as int,
      liliesCollected: json['liliesCollected'] as int,
      heartsCollected: json['heartsCollected'] as int,
    );
  }

  String toStorageString() => jsonEncode(toJson());

  static GameSession fromStorageString(String value) {
    return fromJson(jsonDecode(value) as Map<String, dynamic>);
  }
}
