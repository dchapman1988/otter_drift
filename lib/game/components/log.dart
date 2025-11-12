import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'otter.dart';

class Log extends SpriteAnimationComponent
    with HasCollisionDetection, HasGameReference {
  late CircleHitbox _hitbox;
  double _scrollSpeed = 120.0;
  bool _hasHitOtter = false;
  bool _hasBeenCounted = false;
  Function()? onAvoided;

  Log() : super(size: Vector2(96, 48));

  @override
  Future<void> onLoad() async {
    try {
      final sheet = await game.images.load('sprites/log_animated.png');
      final frameWidth = sheet.width / 4;
      final frameHeight = sheet.height.toDouble();

      animation = SpriteAnimation.fromFrameData(
        sheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.16,
          textureSize: Vector2(frameWidth, frameHeight),
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Log::onLoad failed to load sprite: $e');
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stackTrace,
          context: ErrorDescription('Loading log sprite'),
          library: 'Log component',
        ),
      );
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

  void setOnAvoidedCallback(Function() callback) {
    onAvoided = callback;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move down at scroll speed
    position.y += _scrollSpeed * dt;

    // Check if otter has passed this log without collision
    if (!_hasBeenCounted && !_hasHitOtter) {
      final otter = game.children.whereType<Otter>().firstOrNull;
      if (otter != null && position.y > otter.position.y + otter.size.y) {
        _hasBeenCounted = true;
        onAvoided?.call();
      }
    }

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
