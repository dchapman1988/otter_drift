class PlayerAchievement {
  final String name;
  final String description;
  final String achievementType;
  final int points;
  final String badgeUrl; // Can be a URL or emoji string
  final DateTime? collectedAt;

  const PlayerAchievement({
    required this.name,
    required this.description,
    required this.achievementType,
    required this.points,
    required this.badgeUrl,
    this.collectedAt,
  });

  factory PlayerAchievement.fromJson(Map<String, dynamic> json) {
    return PlayerAchievement(
      name: json['name'] as String,
      description: json['description'] as String,
      achievementType: json['achievement_type'] as String,
      points: json['points'] as int,
      badgeUrl: json['badge_url'] as String,
      collectedAt: json['collected_at'] != null
          ? DateTime.parse(json['collected_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'achievement_type': achievementType,
      'points': points,
      'badge_url': badgeUrl,
      'collected_at': collectedAt?.toIso8601String(),
    };
  }

  /// Check if badgeUrl is a network URL (starts with http)
  bool get isBadgeUrlNetworkImage => badgeUrl.startsWith('http');

  /// Check if badgeUrl is an emoji
  bool get isBadgeUrlEmoji => !isBadgeUrlNetworkImage;

  @override
  String toString() {
    return 'PlayerAchievement(name: $name, achievementType: $achievementType, points: $points, collectedAt: $collectedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerAchievement &&
        other.name == name &&
        other.achievementType == achievementType &&
        other.points == points &&
        other.collectedAt == collectedAt;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        achievementType.hashCode ^
        points.hashCode ^
        collectedAt.hashCode;
  }
}
