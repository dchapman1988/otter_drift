import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'otter.dart';

class Lily extends SpriteComponent with HasCollisionDetection, HasGameReference {
  late CircleHitbox _hitbox;
  double _scrollSpeed = 120.0;
  bool _hasBeenCollected = false;
  Function(int)? onScore;

  Lily() : super(size: Vector2.all(48));

  @override
  Future<void> onLoad() async {
    try {
      sprite = await game.loadSprite('sprites/lily.jpg');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Lily::onLoad failed to load sprite: $e');
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stackTrace,
          context: ErrorDescription('Loading lily sprite'),
          library: 'Lily component',
        ),
      );
    }
    
    // Add circular hitbox for collision detection
    final radius = (size.x < size.y ? size.x : size.y) * 0.35;
    _hitbox = CircleHitbox(radius: radius);
    add(_hitbox);
    
    anchor = Anchor.center;
  }

  void setScrollSpeed(double speed) {
    _scrollSpeed = speed;
  }

  void setOnScoreCallback(Function(int) callback) {
    onScore = callback;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move down at scroll speed
    position.y += _scrollSpeed * dt;
    
    // Check for collision with otter
    if (!_hasBeenCollected) {
      final otter = game.children.whereType<Otter>().firstOrNull;
      if (otter != null && toRect().overlaps(otter.toRect())) {
        _hasBeenCollected = true;
        onScore?.call(10); // Each lily gives 10 points
        removeFromParent();
      }
    }
    
    // Remove if off screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
}
