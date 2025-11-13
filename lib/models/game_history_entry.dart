class GameHistoryEntry {
  final String sessionId;
  final int finalScore;
  final int seed;
  final DateTime startedAt;
  final DateTime endedAt;
  final double gameDuration;
  final int liliesCollected;
  final int obstaclesAvoided;
  final int heartsCollected;
  final double maxSpeedReached;
  final List<Map<String, dynamic>>? highScores;
  final int achievementsEarned;

  const GameHistoryEntry({
    required this.sessionId,
    required this.finalScore,
    required this.seed,
    required this.startedAt,
    required this.endedAt,
    required this.gameDuration,
    required this.liliesCollected,
    required this.obstaclesAvoided,
    required this.heartsCollected,
    required this.maxSpeedReached,
    this.highScores,
    this.achievementsEarned = 0,
  });

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GameHistoryEntry(
      sessionId: json['session_id'] as String,
      finalScore: json['final_score'] as int,
      seed: json['seed'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: DateTime.parse(json['ended_at'] as String),
      gameDuration: (json['game_duration'] as num).toDouble(),
      liliesCollected: json['stats'] != null
          ? (json['stats'] as Map<String, dynamic>)['lilies_collected']
                    as int? ??
                0
          : 0,
      obstaclesAvoided: json['stats'] != null
          ? (json['stats'] as Map<String, dynamic>)['obstacles_avoided']
                    as int? ??
                0
          : 0,
      heartsCollected: json['stats'] != null
          ? (json['stats'] as Map<String, dynamic>)['hearts_collected']
                    as int? ??
                0
          : 0,
      maxSpeedReached: json['stats'] != null
          ? ((json['stats'] as Map<String, dynamic>)['max_speed_reached']
                        as num?)
                    ?.toDouble() ??
                0.0
          : 0.0,
      highScores: json['high_scores'] != null
          ? (json['high_scores'] as List<dynamic>)
                .map((item) => item as Map<String, dynamic>)
                .toList()
          : null,
      achievementsEarned: json['achievements_earned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'final_score': finalScore,
      'seed': seed,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'game_duration': gameDuration,
      'stats': {
        'lilies_collected': liliesCollected,
        'obstacles_avoided': obstaclesAvoided,
        'hearts_collected': heartsCollected,
        'max_speed_reached': maxSpeedReached,
      },
      'high_scores': highScores,
      'achievements_earned': achievementsEarned,
    };
  }

  @override
  String toString() {
    return 'GameHistoryEntry(sessionId: $sessionId, finalScore: $finalScore, seed: $seed)';
  }
}
