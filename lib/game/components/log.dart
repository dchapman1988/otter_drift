import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'otter.dart';

class Log extends SpriteComponent with HasCollisionDetection, HasGameReference {
  late CircleHitbox _hitbox;
  double _scrollSpeed = 120.0;
  bool _hasHitOtter = false;

  Log() : super(size: Vector2(96, 48));

  @override
  Future<void> onLoad() async {
    try {
      sprite = await game.loadSprite('sprites/log.jpg');
    } catch (e) {
      print('Error loading log sprite: $e');
    }
    
    // Add circular hitbox with radius = min(width, height) * 0.35
    final radius = (size.x < size.y ? size.x : size.y) * 0.35;
    _hitbox = CircleHitbox(radius: radius);
    add(_hitbox);
    
    anchor = Anchor.center;
  }

  void setScrollSpeed(double speed) {
    _scrollSpeed = speed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move down at scroll speed
    position.y += _scrollSpeed * dt;
    
    // Remove if off screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  void onCollisionWithOtter() {
    if (_hasHitOtter) return;
    _hasHitOtter = true;
    
    // Find the otter and trigger damage
    final otter = game.children.whereType<Otter>().firstOrNull;
    if (otter != null) {
      otter.takeDamage();
    }
  }

  // Remove the onCollision override since we're handling collision in the main game loop
}
