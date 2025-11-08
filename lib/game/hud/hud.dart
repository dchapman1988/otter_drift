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
  late TextComponent _statsText;
  late TextComponent _saveStatusText;

  int hearts = 3;
  int score = 0;
  double speed = 120.0;
  int seed = 0;
  bool _gameOver = false;

  Function()? onPlayAgain;
  Function()? onQuit;

  @override
  Future<void> onLoad() async {
    // Hearts display (top-left)
    _heartsText = TextComponent(
      text: '❤️ ❤️ ❤️',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.red),
      ),
    );
    add(_heartsText);

    // Score display (top-right)
    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(game.size.x - 120, 20),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 20, color: Colors.white),
      ),
    );
    add(_scoreText);

    // Speed display (center-top)
    _speedText = TextComponent(
      text: 'Speed: x1.0',
      position: Vector2(game.size.x / 2 - 40, 20),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.yellow),
      ),
    );
    add(_speedText);

    // Debug text (bottom-left)
    _debugText = TextComponent(
      text: 'seed=0 speed=120',
      position: Vector2(10, game.size.y - 30),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
    add(_debugText);

    // Game Over overlay (initially hidden) - semi-transparent blue background
    _gameOverOverlay = RectangleComponent(
      size: game.size,
      paint: Paint()
        ..color = const Color(0xCC1A3A50), // Semi-transparent dark blue
    );
    _gameOverOverlay.position = Vector2.zero();
    add(_gameOverOverlay);

    _gameOverText = TextComponent(
      text: 'Game Over!',
      position: Vector2(game.size.x / 2 - 88, game.size.y / 2 - 80),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 36,
          color: const Color(0xFFF59E0B), // Orange/amber
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black87),
          ],
        ),
      ),
    );
    add(_gameOverText);

    _finalScoreText = TextComponent(
      text: 'Final Score: 0',
      position: Vector2(game.size.x / 2 - 86, game.size.y / 2 - 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(_finalScoreText);

    _statsText = TextComponent(
      text: '',
      position: Vector2(game.size.x / 2 - 100, game.size.y / 2 + 20),
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18, color: Colors.white70),
      ),
    );
    add(_statsText);

    _saveStatusText = TextComponent(
      text: '',
      position: Vector2(game.size.x / 2, game.size.y / 2 + 200),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18, color: Colors.yellow),
      ),
    );
    add(_saveStatusText);

    // Hide game over overlay initially
    _gameOverOverlay.removeFromParent();
    _gameOverText.removeFromParent();
    _finalScoreText.removeFromParent();
    _statsText.removeFromParent();
    _saveStatusText.removeFromParent();
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

  void showGameOver({int liliesCollected = 0, int heartsCollected = 0}) {
    _gameOver = true;
    add(_gameOverText);
    add(_finalScoreText);
    add(_statsText);
    add(_saveStatusText);
    _finalScoreText.text = 'Final Score: $score';
    _statsText.text =
        '💗 Hearts: $heartsCollected  🌸 Lilies: $liliesCollected';
    _saveStatusText.text = ''; // Clear previous status
  }

  void setSaveStatus(String status, {bool isSuccess = true}) {
    _saveStatusText.text = status;
    _saveStatusText.textRenderer = TextPaint(
      style: TextStyle(
        fontSize: 16,
        color: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  void hideGameOver() {
    _gameOver = false;
    _gameOverText.removeFromParent();
    _finalScoreText.removeFromParent();
    _statsText.removeFromParent();
    _saveStatusText.removeFromParent();
  }

  bool handleTap(double x, double y) {
    print('HUD handleTap called: x=$x, y=$y, gameOver=$_gameOver');
    if (!_gameOver) return false;

    final tapX = x;
    final tapY = y;

    // Check if tap is on Play Again button
    final playAgainRect = Rect.fromLTWH(
      game.size.x / 2 - 80,
      game.size.y / 2 + 50,
      160,
      40,
    );

    // Check if tap is on Quit button
    final quitRect = Rect.fromLTWH(
      game.size.x / 2 - 80,
      game.size.y / 2 + 110,
      160,
      40,
    );

    print('Button rects - PlayAgain: $playAgainRect, Quit: $quitRect');
    print('Tap point: ($tapX, $tapY)');

    if (playAgainRect.contains(Offset(tapX, tapY))) {
      print('Play Again button tapped!');
      onPlayAgain?.call();
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
      // Draw semi-transparent dark blue background
      final backgroundPaint = Paint()..color = const Color(0xCC1A3A50);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, game.size.x, game.size.y),
        backgroundPaint,
      );

      // Draw buttons with better styling
      final buttonPaint = Paint()
        ..color =
            const Color(0xFF0EA5E9) // Nice blue
        ..style = PaintingStyle.fill;

      // Play Again button
      final playAgainRect = Rect.fromLTWH(
        game.size.x / 2 - 80,
        game.size.y / 2 + 50,
        160,
        40,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(playAgainRect, const Radius.circular(12)),
        buttonPaint,
      );

      // Quit button
      final quitRect = Rect.fromLTWH(
        game.size.x / 2 - 80,
        game.size.y / 2 + 110,
        160,
        40,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(quitRect, const Radius.circular(12)),
        buttonPaint,
      );

      // Button text
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

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
