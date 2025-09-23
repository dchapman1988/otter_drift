import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import 'components/otter.dart';
import 'components/log.dart';
import 'components/lily.dart';
import 'components/river_bg.dart';
import 'hud/hud.dart';
import '../services/backend.dart';
import '../util/rng.dart';

class OtterGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  late RiverBg _riverBg;
  late Otter _otter;
  late Hud _hud;
  late SeededRandom _rng;
  
  int hearts = 3;
  int score = 0;
  double baseSpeed = 120.0;
  double currentSpeed = 120.0;
  int seed = 0;
  double gameTime = 0.0;
  double lastSpeedIncrease = 0.0;
  double nextSpawnTime = 0.0;
  String sessionId = '';
  
  @override
  Future<void> onLoad() async {
    // Initialize seeded random
    seed = DateTime.now().millisecondsSinceEpoch;
    _rng = SeededRandom(seed: seed);
    sessionId = const Uuid().v4();
    
    // Preload all sprites - temporarily disabled due to invalid PNG files
    // await _preloadSprites();
    
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

  Future<void> _preloadSprites() async {
    try {
      await Sprite.load('sprites/otter.png');
      await Sprite.load('sprites/log.png');
      await Sprite.load('sprites/lily.png');
      await Sprite.load('sprites/heart.png');
      await Sprite.load('sprites/river_tile.png');
      print('All sprites loaded successfully');
    } catch (e) {
      print('Error loading sprites: $e');
      // Continue anyway - components will handle missing sprites
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    print('Game onTapDown: hearts=$hearts, localPos=(${event.localPosition.x}, ${event.localPosition.y})');
    // If game over, let HUD handle the tap
    if (hearts <= 0) {
      final handled = _hud.handleTap(event.localPosition.x, event.localPosition.y);
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
    // 70% logs, 30% lilies
    final isLog = _rng.nextDouble() < 0.7;
    
    // Random X position within river banks
    final margin = 64.0; // Half sprite width
    final x = _rng.rangeDouble(margin, size.x - margin);
    
    if (isLog) {
      final log = Log();
      log.position = Vector2(x, -64.0); // Spawn off-screen top
      log.setScrollSpeed(currentSpeed);
      add(log);
    } else {
      final lily = Lily();
      lily.position = Vector2(x, -64.0); // Spawn off-screen top
      lily.setScrollSpeed(currentSpeed);
      lily.setOnScoreCallback((points) => addScore(points));
      add(lily);
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
    _hud.updateScore(score);
  }

  void gameOver() {
    // Stop background scrolling
    _riverBg.setScrollSpeed(0);
    
    // Hide all game sprites
    _otter.removeFromParent();
    children.whereType<Log>().forEach((log) => log.removeFromParent());
    children.whereType<Lily>().forEach((lily) => lily.removeFromParent());
    
    // Show game over screen
    _hud.showGameOver();
  }

  void restart() {
    // Reset game state
    hearts = 3;
    score = 0;
    currentSpeed = 120.0;
    gameTime = 0.0;
    lastSpeedIncrease = 0.0;
    
    // New seed for new game
    seed = DateTime.now().millisecondsSinceEpoch;
    _rng = SeededRandom(seed: seed);
    sessionId = const Uuid().v4();
    
    // Clear all obstacles
    children.whereType<Log>().toList().forEach((log) => log.removeFromParent());
    children.whereType<Lily>().toList().forEach((lily) => lily.removeFromParent());
    
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
    final result = await BackendService.saveScore(
      name: 'Player', // Could be made configurable
      score: score,
      sessionId: sessionId,
    );
    
    if (result != null) {
      // Show success message
      // In a real implementation, you might use a snackbar or toast
      print('Score saved successfully!');
    } else {
      // Show error message
      print('Failed to save score');
    }
  }

  void quitGame() {
    // Exit the Flutter app
    SystemNavigator.pop();
  }

  // Input handling will be added later
}
