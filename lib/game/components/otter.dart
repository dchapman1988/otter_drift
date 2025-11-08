import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Otter extends SpriteComponent with HasCollisionDetection, HasGameReference {
  late CircleHitbox _hitbox;
  double _targetX = 0;
  final double _maxSpeed = 800.0; // px/sec
  double _invulnerableUntil = 0;
  bool _isFlashing = false;
  double _flashDuration = 0;
  
  Otter() : super(size: Vector2.all(64));
  
  @override
  Future<void> onLoad() async {
    try {
      sprite = await game.loadSprite('sprites/otter.jpg');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Otter::onLoad failed to load sprite: $e');
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stackTrace,
          context: ErrorDescription('Loading otter sprite'),
          library: 'Otter component',
        ),
      );
    }
    
    // Position at 70% of screen height
    position = Vector2(game.size.x / 2, game.size.y * 0.7);
    _targetX = position.x;
    
    // Add circular hitbox with radius = min(width, height) * 0.35
    final radius = (size.x < size.y ? size.x : size.y) * 0.35;
    _hitbox = CircleHitbox(radius: radius);
    add(_hitbox);
    
    anchor = Anchor.center;
  }


  @override
  void update(double dt) {
    super.update(dt);
    
    // Lerp towards target X position
    final dx = _targetX - position.x;
    final maxDx = _maxSpeed * dt;
    
    if (dx.abs() <= maxDx) {
      position.x = _targetX;
    } else {
      position.x += dx.sign * maxDx;
    }
    
    // Clamp to river banks (assuming river is full width with some margin)
    final margin = size.x * 0.5;
    position.x = position.x.clamp(margin, game.size.x - margin);
    _targetX = position.x;
    
    // Handle invulnerability and flashing
    if (_invulnerableUntil > 0) {
      _invulnerableUntil -= dt;
      if (_invulnerableUntil <= 0) {
        _invulnerableUntil = 0;
        _isFlashing = false;
      }
    }
    
    // Handle flash effect
    if (_isFlashing) {
      _flashDuration -= dt;
      if (_flashDuration <= 0) {
        _isFlashing = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Apply flash effect if active
    if (_isFlashing) {
      final paint = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color.fromRGBO(255, 0, 0, 0.5),
          BlendMode.modulate,
        );
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.x, size.y), paint);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  void setTargetX(double x) {
    _targetX = x;
  }

  void takeDamage() {
    if (isInvulnerable()) return;
    
    _invulnerableUntil = 0.5; // 500ms invulnerability
    _isFlashing = true;
    _flashDuration = 0.25; // 250ms flash
  }

  bool isInvulnerable() => _invulnerableUntil > 0;
}
