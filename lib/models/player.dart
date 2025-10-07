class Player {
  final int id;
  final String email;
  final String username;
  final String displayName;
  final int totalScore;
  final int gamesPlayed;

  const Player({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.totalScore,
    required this.gamesPlayed,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String? ?? json['username'] as String,
      totalScore: json['total_score'] as int? ?? 0,
      gamesPlayed: json['games_played'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'total_score': totalScore,
      'games_played': gamesPlayed,
    };
  }

  Player copyWith({
    int? id,
    String? email,
    String? username,
    String? displayName,
    int? totalScore,
    int? gamesPlayed,
  }) {
    return Player(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, email: $email, username: $username, displayName: $displayName, totalScore: $totalScore, gamesPlayed: $gamesPlayed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player &&
        other.id == id &&
        other.email == email &&
        other.username == username &&
        other.displayName == displayName &&
        other.totalScore == totalScore &&
        other.gamesPlayed == gamesPlayed;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        username.hashCode ^
        displayName.hashCode ^
        totalScore.hashCode ^
        gamesPlayed.hashCode;
  }
}

