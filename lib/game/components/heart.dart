import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'otter.dart';

class Heart extends SpriteAnimationComponent
    with HasCollisionDetection, HasGameReference {
  late CircleHitbox _hitbox;
  double _scrollSpeed = 120.0;
  bool _hasBeenCollected = false;
  Function()? onCollect;

  Heart() : super(size: Vector2.all(48));

  @override
  Future<void> onLoad() async {
    try {
      final sheet = await game.images.load('sprites/heart_animated.png');
      final frameWidth = sheet.width / 4;
      final frameHeight = sheet.height.toDouble();

      animation = SpriteAnimation.fromFrameData(
        sheet,
        SpriteAnimationData.sequenced(
          amount: 4,
          stepTime: 0.12,
          textureSize: Vector2(frameWidth, frameHeight),
        ),
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Heart::onLoad failed to load sprite: $e');
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stackTrace,
          context: ErrorDescription('Loading heart sprite'),
          library: 'Heart component',
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
        FlameAudio.play('heart_collect.wav');
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
