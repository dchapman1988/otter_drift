import 'player_info.dart';

class LeaderboardEntry {
  final int rank;
  final int score;
  final String playerName;
  final DateTime achievedAt;
  final bool isGuest;
  final PlayerInfo? player; // Only present for authenticated players

  const LeaderboardEntry({
    required this.rank,
    required this.score,
    required this.playerName,
    required this.achievedAt,
    required this.isGuest,
    this.player,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      score: json['score'] as int,
      playerName: json['player_name'] as String,
      achievedAt: DateTime.parse(json['achieved_at'] as String),
      isGuest: json['is_guest'] as bool? ?? false,
      player: json['player'] != null
          ? PlayerInfo.fromJson(json['player'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'score': score,
      'player_name': playerName,
      'achieved_at': achievedAt.toIso8601String(),
      'is_guest': isGuest,
      'player': player?.toJson(),
    };
  }

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, score: $score, playerName: $playerName, isGuest: $isGuest)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.rank == rank &&
        other.score == score &&
        other.playerName == playerName &&
        other.achievedAt == achievedAt &&
        other.isGuest == isGuest &&
        other.player == player;
  }

  @override
  int get hashCode {
    return rank.hashCode ^
        score.hashCode ^
        playerName.hashCode ^
        achievedAt.hashCode ^
        isGuest.hashCode ^
        player.hashCode;
  }
}

