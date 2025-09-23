import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class RiverBg extends RectangleComponent with HasGameReference {
  late RectangleComponent _tile1;
  late RectangleComponent _tile2;
  double _scrollSpeed = 120.0;
  double _tileHeight = 0;

  RiverBg() : super() {
    paint = Paint()..color = Colors.cyan;
  }

  @override
  Future<void> onLoad() async {
    _tileHeight = size.y;
    
    _tile1 = RectangleComponent(
      size: Vector2(size.x, _tileHeight),
      position: Vector2.zero(),
      paint: Paint()..color = Colors.cyan,
    );
    
    _tile2 = RectangleComponent(
      size: Vector2(size.x, _tileHeight),
      position: Vector2(0, -_tileHeight),
      paint: Paint()..color = Colors.cyan,
    );
    
    add(_tile1);
    add(_tile2);
  }

  void setScrollSpeed(double speed) {
    _scrollSpeed = speed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move tiles down
    _tile1.position.y += _scrollSpeed * dt;
    _tile2.position.y += _scrollSpeed * dt;
    
    // Wrap tiles when they go off screen
    if (_tile1.position.y > _tileHeight) {
      _tile1.position.y = _tile2.position.y - _tileHeight;
    }
    
    if (_tile2.position.y > _tileHeight) {
      _tile2.position.y = _tile1.position.y - _tileHeight;
    }
  }
}
