import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/models/player.dart';
import 'package:flutter_frontend/models/player_profile.dart';

void main() {
  group('Player model', () {
    test('fromJson populates defaults when fields missing', () {
      final json = {
        'id': 1,
        'email': 'user@example.com',
        'username': 'otterfan',
        'display_name': null,
        'total_score': null,
        'games_played': null,
      };

      final player = Player.fromJson(json);

      expect(player.id, 1);
      expect(player.email, 'user@example.com');
      expect(player.username, 'otterfan');
      expect(player.displayName, 'otterfan'); // falls back to username
      expect(player.totalScore, 0);
      expect(player.gamesPlayed, 0);
      expect(player.avatarUrl, isNull);
      expect(player.profile, isNull);
    });

    test('fromJson parses nested profile data', () {
      final json = {
        'id': 2,
        'email': 'player@example.com',
        'username': 'river_runner',
        'display_name': 'River Runner',
        'total_score': 4200,
        'games_played': 12,
        'avatar_url': 'https://example.com/avatar.png',
        'profile': {
          'favorite_raft': 'Swift Current',
          'bio': 'Floating down the river.',
        },
      };

      final player = Player.fromJson(json);

      expect(player.displayName, 'River Runner');
      expect(player.totalScore, 4200);
      expect(player.gamesPlayed, 12);
      expect(player.avatarUrl, 'https://example.com/avatar.png');
      expect(player.profile, isA<PlayerProfile>());
    });

    test('copyWith returns updated values without mutating original', () {
      const original = Player(
        id: 10,
        email: 'original@example.com',
        username: 'original_user',
        displayName: 'Original User',
        totalScore: 100,
        gamesPlayed: 5,
      );

      final updated = original.copyWith(
        email: 'new@example.com',
        totalScore: 150,
      );

      expect(updated.email, 'new@example.com');
      expect(updated.totalScore, 150);
      expect(updated.username, original.username);
      expect(updated.gamesPlayed, original.gamesPlayed);

      // Ensure original untouched
      expect(original.email, 'original@example.com');
      expect(original.totalScore, 100);
    });

    test('equality compares field-by-field', () {
      const playerA = Player(
        id: 1,
        email: 'a@example.com',
        username: 'userA',
        displayName: 'User A',
        totalScore: 50,
        gamesPlayed: 3,
      );

      const playerB = Player(
        id: 1,
        email: 'a@example.com',
        username: 'userA',
        displayName: 'User A',
        totalScore: 50,
        gamesPlayed: 3,
      );

      const playerC = Player(
        id: 2,
        email: 'c@example.com',
        username: 'userC',
        displayName: 'User C',
        totalScore: 75,
        gamesPlayed: 4,
      );

      expect(playerA, equals(playerB));
      expect(playerA == playerC, isFalse);
      expect(playerA.hashCode, equals(playerB.hashCode));
    });
  });
}

