import 'player_achievement.dart';

class PlayerAchievements {
  final String username;
  final int totalAchievements;
  final List<PlayerAchievement> achievements;

  const PlayerAchievements({
    required this.username,
    required this.totalAchievements,
    required this.achievements,
  });

  factory PlayerAchievements.fromJson(Map<String, dynamic> json) {
    final achievementsList = json['achievements'] as List<dynamic>? ?? [];
    return PlayerAchievements(
      username: json['username'] as String,
      totalAchievements: json['total_achievements'] as int,
      achievements: achievementsList
          .map((achievementJson) => PlayerAchievement.fromJson(
                achievementJson as Map<String, dynamic>,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'total_achievements': totalAchievements,
      'achievements': achievements.map((a) => a.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'PlayerAchievements(username: $username, totalAchievements: $totalAchievements, achievements: ${achievements.length})';
  }
}

