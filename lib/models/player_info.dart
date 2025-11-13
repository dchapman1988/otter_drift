class PlayerInfo {
  final String username;
  final String? avatarUrl;

  const PlayerInfo({required this.username, this.avatarUrl});

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    final avatarData = json['avatar'];
    return PlayerInfo(
      username: json['username'] as String,
      avatarUrl:
          json['avatar_url'] as String? ??
          (avatarData is Map<String, dynamic>
              ? avatarData['url'] as String?
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'avatar_url': avatarUrl};
  }

  @override
  String toString() {
    return 'PlayerInfo(username: $username, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerInfo &&
        other.username == username &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return username.hashCode ^ avatarUrl.hashCode;
  }
}
