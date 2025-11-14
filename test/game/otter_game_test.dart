import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/game/otter_game.dart';
import 'package:flutter_frontend/models/player.dart';

void main() {
  group('OtterGame (without onLoad)', () {
    test('uses expected default values before initialization', () {
      final otterGame = OtterGame();

      expect(otterGame.hearts, 3);
      expect(otterGame.score, 0);
      expect(otterGame.currentSpeed, 120.0);
      expect(otterGame.baseSpeed, 120.0);
      expect(otterGame.isPaused, false);
      expect(otterGame.seed, 0);
      expect(otterGame.sessionId, isEmpty);
    });

    test('score field can be mutated safely', () {
      final otterGame = OtterGame();

      otterGame.score = 10;
      expect(otterGame.score, 10);

      otterGame.score = 25;
      expect(otterGame.score, 25);
    });

    test('heart counter can be mutated safely', () {
      final otterGame = OtterGame();

      otterGame.hearts = 2;
      expect(otterGame.hearts, 2);

      otterGame.hearts = 0;
      expect(otterGame.hearts, 0);
    });

    test('stat counters are mutable prior to load', () {
      final otterGame = OtterGame();

      otterGame.logsAvoided = 5;
      otterGame.liliesCollected = 3;
      otterGame.heartsCollected = 2;

      expect(otterGame.logsAvoided, 5);
      expect(otterGame.liliesCollected, 3);
      expect(otterGame.heartsCollected, 2);
    });

    test('speed and game time fields can be adjusted', () {
      final otterGame = OtterGame();

      otterGame.currentSpeed = 150.0;
      expect(otterGame.currentSpeed, 150.0);

      otterGame.gameTime = 42.5;
      expect(otterGame.gameTime, 42.5);
    });

    test('player metadata is preserved', () {
      final player = Player(
        id: 123,
        username: 'testuser',
        email: 'test@example.com',
        displayName: 'Test User',
        totalScore: 0,
        gamesPlayed: 0,
      );

      final gameWithPlayer = OtterGame(player: player, isGuestMode: false);
      final guestGame = OtterGame(isGuestMode: true);

      expect(gameWithPlayer.player, same(player));
      expect(gameWithPlayer.isGuestMode, false);
      expect(guestGame.player, isNull);
      expect(guestGame.isGuestMode, true);
    });
  });
}
