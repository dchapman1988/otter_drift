import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Hud extends Component with HasGameReference {
  late TextComponent _heartsText;
  late TextComponent _scoreText;
  late TextComponent _speedText;
  late TextComponent _debugText;
  late RectangleComponent _gameOverOverlay;
  late TextComponent _gameOverText;
  late TextComponent _finalScoreText;
  
  int hearts = 3;
  int score = 0;
  double speed = 120.0;
  int seed = 0;
  bool _gameOver = false;
  
  Function()? onPlayAgain;
  Function()? onSaveScore;
  Function()? onQuit;

  @override
  Future<void> onLoad() async {
    // Hearts display (top-left)
    _heartsText = TextComponent(
      text: '❤️ ❤️ ❤️',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.red,
        ),
      ),
    );
    add(_heartsText);

    // Score display (top-right)
    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(game.size.x - 120, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
    add(_scoreText);

    // Speed display (center-top)
    _speedText = TextComponent(
      text: 'Speed: x1.0',
      position: Vector2(game.size.x / 2 - 40, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.yellow,
        ),
      ),
    );
    add(_speedText);

    // Debug text (bottom-left)
    _debugText = TextComponent(
      text: 'seed=0 speed=120',
      position: Vector2(10, game.size.y - 30),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
    );
    add(_debugText);

    // Game Over overlay (initially hidden)
    _gameOverOverlay = RectangleComponent(
      size: game.size,
      paint: Paint()..color = Colors.black,
    );
    _gameOverOverlay.position = Vector2.zero();
    add(_gameOverOverlay);

    _gameOverText = TextComponent(
      text: 'Game Over!',
      position: Vector2(game.size.x / 2 - 80, game.size.y / 2 - 80),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_gameOverText);

    _finalScoreText = TextComponent(
      text: 'Final Score: 0',
      position: Vector2(game.size.x / 2 - 80, game.size.y / 2 - 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
    add(_finalScoreText);

    // Hide game over overlay initially
    _gameOverOverlay.removeFromParent();
    _gameOverText.removeFromParent();
    _finalScoreText.removeFromParent();
  }

  void updateHearts(int newHearts) {
    hearts = newHearts;
    _heartsText.text = '❤️' * hearts + '💔' * (3 - hearts);
  }

  void updateScore(int newScore) {
    score = newScore;
    _scoreText.text = 'Score: $score';
  }

  void updateSpeed(double newSpeed) {
    speed = newSpeed;
    final speedFactor = (speed / 120.0).toStringAsFixed(1);
    _speedText.text = 'Speed: x$speedFactor';
  }

  void updateSeed(int newSeed) {
    seed = newSeed;
    _debugText.text = 'seed=$seed speed=${speed.toStringAsFixed(0)}';
  }

  void showGameOver() {
    _gameOver = true;
    add(_gameOverText);
    add(_finalScoreText);
    _finalScoreText.text = 'Final Score: $score';
  }

  void hideGameOver() {
    _gameOver = false;
    _gameOverText.removeFromParent();
    _finalScoreText.removeFromParent();
  }

  bool handleTap(double x, double y) {
    print('HUD handleTap called: x=$x, y=$y, gameOver=$_gameOver');
    if (!_gameOver) return false;

    final tapX = x;
    final tapY = y;

    // Check if tap is on Play Again button
    final playAgainRect = Rect.fromLTWH(
      game.size.x / 2 - 80,
      game.size.y / 2 + 20,
      160,
      40,
    );

    // Check if tap is on Save Score button
    final saveScoreRect = Rect.fromLTWH(
      game.size.x / 2 - 80,
      game.size.y / 2 + 70,
      160,
      40,
    );

    // Check if tap is on Quit button
    final quitRect = Rect.fromLTWH(
      game.size.x / 2 - 80,
      game.size.y / 2 + 120,
      160,
      40,
    );

    print('Button rects - PlayAgain: $playAgainRect, SaveScore: $saveScoreRect, Quit: $quitRect');
    print('Tap point: ($tapX, $tapY)');
    
    if (playAgainRect.contains(Offset(tapX, tapY))) {
      print('Play Again button tapped!');
      onPlayAgain?.call();
      return true;
    } else if (saveScoreRect.contains(Offset(tapX, tapY))) {
      print('Save Score button tapped!');
      onSaveScore?.call();
      return true;
    } else if (quitRect.contains(Offset(tapX, tapY))) {
      print('Quit button tapped!');
      onQuit?.call();
      return true;
    }

    return false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_gameOver) {
      // Draw the black background first
      final backgroundPaint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(0, 0, game.size.x, game.size.y), backgroundPaint);
      // Draw buttons
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      // Play Again button
      final playAgainRect = Rect.fromLTWH(
        game.size.x / 2 - 80,
        game.size.y / 2 + 20,
        160,
        40,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(playAgainRect, const Radius.circular(8)),
        paint,
      );

      // Save Score button
      final saveScoreRect = Rect.fromLTWH(
        game.size.x / 2 - 80,
        game.size.y / 2 + 70,
        160,
        40,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(saveScoreRect, const Radius.circular(8)),
        paint,
      );

      // Quit button
      final quitRect = Rect.fromLTWH(
        game.size.x / 2 - 80,
        game.size.y / 2 + 120,
        160,
        40,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(quitRect, const Radius.circular(8)),
        paint,
      );

      // Button text
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      textPainter.text = const TextSpan(
        text: 'Play Again',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          playAgainRect.center.dx - textPainter.width / 2,
          playAgainRect.center.dy - textPainter.height / 2,
        ),
      );

      textPainter.text = const TextSpan(
        text: 'Save Score',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          saveScoreRect.center.dx - textPainter.width / 2,
          saveScoreRect.center.dy - textPainter.height / 2,
        ),
      );

      textPainter.text = const TextSpan(
        text: 'Quit Game',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          quitRect.center.dx - textPainter.width / 2,
          quitRect.center.dy - textPainter.height / 2,
        ),
      );
    }
  }
}
