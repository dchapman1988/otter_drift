class PlayerProfile {
  final String? bio;
  final String? favoriteOtterFact;
  final String? title;
  final String? profileBannerUrl;
  final String? location;

  const PlayerProfile({
    this.bio,
    this.favoriteOtterFact,
    this.title,
    this.profileBannerUrl,
    this.location,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      bio: json['bio'] as String?,
      favoriteOtterFact: json['favorite_otter_fact'] as String?,
      title: json['title'] as String?,
      profileBannerUrl: json['profile_banner_url'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'favorite_otter_fact': favoriteOtterFact,
      'title': title,
      'profile_banner_url': profileBannerUrl,
      'location': location,
    };
  }

  PlayerProfile copyWith({
    String? bio,
    String? favoriteOtterFact,
    String? title,
    String? profileBannerUrl,
    String? location,
  }) {
    return PlayerProfile(
      bio: bio ?? this.bio,
      favoriteOtterFact: favoriteOtterFact ?? this.favoriteOtterFact,
      title: title ?? this.title,
      profileBannerUrl: profileBannerUrl ?? this.profileBannerUrl,
      location: location ?? this.location,
    );
  }

  bool get isEmpty {
    return bio?.isEmpty != false &&
           favoriteOtterFact?.isEmpty != false &&
           title?.isEmpty != false &&
           profileBannerUrl?.isEmpty != false &&
           location?.isEmpty != false;
  }

  @override
  String toString() {
    return 'PlayerProfile(bio: $bio, favoriteOtterFact: $favoriteOtterFact, title: $title, profileBannerUrl: $profileBannerUrl, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerProfile &&
        other.bio == bio &&
        other.favoriteOtterFact == favoriteOtterFact &&
        other.title == title &&
        other.profileBannerUrl == profileBannerUrl &&
        other.location == location;
  }

  @override
  int get hashCode {
    return bio.hashCode ^
        favoriteOtterFact.hashCode ^
        title.hashCode ^
        profileBannerUrl.hashCode ^
        location.hashCode;
  }
}

