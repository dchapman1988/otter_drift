import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'otter.dart';

class Heart extends RectangleComponent with HasCollisionDetection, HasGameReference {
  late CircleHitbox _hitbox;
  double _scrollSpeed = 120.0;
  bool _hasBeenCollected = false;
  Function()? onCollect;

  Heart() : super(size: Vector2.all(48)) {
    paint = Paint()..color = Colors.red;
  }

  @override
  Future<void> onLoad() async {
    // Add circular hitbox for collision detection
    final radius = (size.x < size.y ? size.x : size.y) * 0.35;
    _hitbox = CircleHitbox(radius: radius);
    add(_hitbox);
    
    anchor = Anchor.center;
  }

  void setScrollSpeed(double speed) {
    _scrollSpeed = speed;
  }

  void setOnCollectCallback(Function() callback) {
    onCollect = callback;
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
        onCollect?.call();
        removeFromParent();
      }
    }
    
    // Remove if off screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
}

