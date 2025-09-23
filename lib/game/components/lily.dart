import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'otter.dart';

class Lily extends RectangleComponent with HasGameReference {
  double _scrollSpeed = 120.0;
  bool _hasBeenCounted = false;
  Function(int)? onScore;

  Lily() : super(size: Vector2.all(128)) {
    paint = Paint()..color = Colors.pink;
  }

  @override
  Future<void> onLoad() async {
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
    
    // Check if otter has passed this lily (no collision required)
    if (!_hasBeenCounted) {
      final otter = game.children.whereType<Otter>().firstOrNull;
      if (otter != null && position.y > otter.position.y) {
        _hasBeenCounted = true;
        onScore?.call(1);
        // TODO: Play "ding" sound effect
      }
    }
    
    // Remove if off screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
}
