import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import 'components/otter.dart';
import 'components/log.dart';
import 'components/lily.dart';
import 'components/heart.dart';
import 'components/river_bg.dart';
import 'hud/hud.dart';
import '../services/backend.dart';
import '../util/rng.dart';
import '../models/player.dart';

class OtterGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  late RiverBg _riverBg;
  late Otter _otter;
  late Hud _hud;
  late SeededRandom _rng;

  final Player? player;
  final bool isGuestMode;

  int hearts = 3;
  int score = 0;
  double baseSpeed = 120.0;
  double currentSpeed = 120.0;
  int seed = 0;
  double gameTime = 0.0;
  double lastSpeedIncrease = 0.0;
  double nextSpawnTime = 0.0;
  String sessionId = '';
  DateTime? gameStartedAt;
  int logsAvoided = 0;
  int liliesCollected = 0;
  int heartsCollected = 0;

  OtterGame({this.player, this.isGuestMode = false});

  @override
  Future<void> onLoad() async {
    // Initialize seeded random
    seed = DateTime.now().millisecondsSinceEpoch;
    _rng = SeededRandom(seed: seed);
    sessionId = const Uuid().v4();
    gameStartedAt = DateTime.now();

    // Create background
    _riverBg = RiverBg();
    _riverBg.size = size;
    add(_riverBg);

    // Create otter
    _otter = Otter();
    add(_otter);

    // Create HUD
    _hud = Hud();
    _hud.onPlayAgain = restart;
    _hud.onSaveScore = saveScore;
    _hud.onQuit = quitGame;
    add(_hud);

    // Update HUD initial values
    _hud.updateHearts(hearts);
    _hud.updateScore(score);
    _hud.updateSpeed(currentSpeed);
    _hud.updateSeed(seed);

    // Schedule first spawn
    nextSpawnTime = _rng.nextPoissonSpawnTime(1.2);

    // Set up collision detection
    // The otter already has its hitbox in its onLoad method
  }

  @override
  void onTapDown(TapDownEvent event) {
    print(
      'Game onTapDown: hearts=$hearts, localPos=(${event.localPosition.x}, ${event.localPosition.y})',
    );
    // If game over, let HUD handle the tap
    if (hearts <= 0) {
      final handled = _hud.handleTap(
        event.localPosition.x,
        event.localPosition.y,
      );
      print('HUD handled tap: $handled');
      if (handled) return;
    } else {
      // Move otter to tap position
      _otter.setTargetX(event.localPosition.x);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Clamp dt to prevent physics spikes
    dt = dt.clamp(0.0, 1.0 / 30.0);

    // Stop game logic if game over
    if (hearts <= 0) {
      return;
    }

    gameTime += dt;

    // Speed increase every 20 seconds
    if (gameTime - lastSpeedIncrease >= 20.0) {
      lastSpeedIncrease = gameTime;
      currentSpeed = (currentSpeed * 1.1).clamp(120.0, 240.0);
      _riverBg.setScrollSpeed(currentSpeed);
      _hud.updateSpeed(currentSpeed);
    }

    // Spawn obstacles
    nextSpawnTime -= dt;
    if (nextSpawnTime <= 0) {
      spawnObstacle();
      nextSpawnTime = _rng.nextPoissonSpawnTime(1.2);
    }

    // Update obstacle speeds
    for (final obstacle in children.whereType<Log>()) {
      obstacle.setScrollSpeed(currentSpeed);
    }
    for (final lily in children.whereType<Lily>()) {
      lily.setScrollSpeed(currentSpeed);
    }
    for (final heart in children.whereType<Heart>()) {
      heart.setScrollSpeed(currentSpeed);
    }

    // Check for collisions between otter and logs
    for (final log in children.whereType<Log>()) {
      if (_otter.toRect().overlaps(log.toRect())) {
        if (!_otter.isInvulnerable()) {
          takeDamage();
          _otter.takeDamage();
        }
      }
    }

    // Update HUD debug info
    _hud.updateSeed(seed);
  }

  void spawnObstacle() {
    // 60% logs, 25% lilies, 15% hearts
    final roll = _rng.nextDouble();

    // Random X position within river banks
    // Use largest sprite dimension for margin (log is 96 wide)
    final margin = 48.0; // Half of largest sprite width
    final x = _rng.rangeDouble(margin, size.x - margin);

    if (roll < 0.6) {
      // Spawn log
      final log = Log();
      log.position = Vector2(x, -48.0); // Spawn off-screen top
      log.setScrollSpeed(currentSpeed);
      log.setOnAvoidedCallback(() => onLogAvoided());
      add(log);
    } else if (roll < 0.85) {
      // Spawn lily
      final lily = Lily();
      lily.position = Vector2(x, -48.0); // Spawn off-screen top
      lily.setScrollSpeed(currentSpeed);
      lily.setOnScoreCallback((points) => addScore(points));
      add(lily);
    } else {
      // Spawn heart
      final heart = Heart();
      heart.position = Vector2(x, -48.0); // Spawn off-screen top
      heart.setScrollSpeed(currentSpeed);
      heart.setOnCollectCallback(() => collectHeart());
      add(heart);
    }
  }

  void takeDamage() {
    if (hearts <= 0) return;

    hearts--;
    _hud.updateHearts(hearts);

    if (hearts <= 0) {
      gameOver();
    }
  }

  void addScore(int points) {
    score += points;
    // Count number of lilies collected, not points
    if (points == 10) {
      // Lilies give 10 points each
      liliesCollected += 1;
    }
    _hud.updateScore(score);
  }

  void onLogAvoided() {
    logsAvoided++;
    addScore(1); // Logs give 1 point each when avoided
  }

  void collectHeart() {
    heartsCollected++;
    // Restore health if not at max (max is 3)
    if (hearts < 3) {
      hearts++;
      _hud.updateHearts(hearts);
    }
  }

  void gameOver() {
    // Stop background scrolling
    _riverBg.setScrollSpeed(0);

    // Hide all game sprites
    _otter.removeFromParent();
    children.whereType<Log>().forEach((log) => log.removeFromParent());
    children.whereType<Lily>().forEach((lily) => lily.removeFromParent());
    children.whereType<Heart>().forEach((heart) => heart.removeFromParent());

    // Show game over screen with stats
    _hud.showGameOver(
      liliesCollected: liliesCollected,
      heartsCollected: heartsCollected,
    );
  }

  void restart() {
    // Reset game state
    hearts = 3;
    score = 0;
    currentSpeed = 120.0;
    gameTime = 0.0;
    lastSpeedIncrease = 0.0;
    logsAvoided = 0;
    liliesCollected = 0;
    heartsCollected = 0;

    // New seed for new game
    seed = DateTime.now().millisecondsSinceEpoch;
    _rng = SeededRandom(seed: seed);
    sessionId = const Uuid().v4();
    gameStartedAt = DateTime.now();

    // Clear all obstacles
    children.whereType<Log>().toList().forEach((log) => log.removeFromParent());
    children.whereType<Lily>().toList().forEach(
      (lily) => lily.removeFromParent(),
    );
    children.whereType<Heart>().toList().forEach(
      (heart) => heart.removeFromParent(),
    );

    // Restore otter if it was hidden
    if (!children.contains(_otter)) {
      add(_otter);
    }

    // Reset background speed
    _riverBg.setScrollSpeed(currentSpeed);

    // Reset HUD
    _hud.updateHearts(hearts);
    _hud.updateScore(score);
    _hud.updateSpeed(currentSpeed);
    _hud.updateSeed(seed);
    _hud.hideGameOver();

    // Reset otter position
    _otter.position = Vector2(size.x / 2, size.y * 0.7);

    // Schedule first spawn
    nextSpawnTime = _rng.nextPoissonSpawnTime(1.2);
  }

  void saveScore() async {
    // Show loading or disable button temporarily
    final playerName = player?.displayName ?? 'Guest Player';

    final result = await BackendService.saveScore(
      sessionId: sessionId,
      playerName: playerName,
      seed: seed,
      startedAt: gameStartedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      finalScore: score,
      gameDuration: gameTime,
      maxSpeedReached: currentSpeed,
      obstaclesAvoided: logsAvoided,
      liliesCollected: liliesCollected,
      heartsCollected: heartsCollected,
    );

    if (result != null) {
      // Show success message
      _hud.setSaveStatus('✓ Score saved!', isSuccess: true);
      print('Score saved successfully!');
    } else {
      // Show error message
      _hud.setSaveStatus('✗ Failed to save', isSuccess: false);
      print('Failed to save score');
    }
  }

  void quitGame() {
    // Exit the Flutter app
    SystemNavigator.pop();
  }

  // Input handling will be added later
}
