import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Spacing constants for consistent layout
class HudSpacing {
  // Base spacing unit (8px grid system)
  static const double unit = 8.0;

  // Spacing multipliers
  static const double xs = unit; // 8px
  static const double sm = unit * 2; // 16px
  static const double md = unit * 3; // 24px
  static const double lg = unit * 4; // 32px
  static const double xl = unit * 6; // 48px
  static const double xxl = unit * 8; // 64px

  // Game Over screen spacing
  static const double gameOverTitleSpacing =
      xxl * 1.5; // 96px above center (moves everything up significantly)
  static const double gameOverScoreSpacing = md; // 24px between title and score
  static const double gameOverStatsSpacing = md; // 24px between score and stats
  static const double gameOverButtonSpacing =
      xl; // 48px between stats and buttons
  static const double gameOverButtonGap = sm; // 16px between buttons
  static const double gameOverStatusSpacing = lg; // 32px below buttons

  // Button dimensions
  static const double buttonWidth = 200.0;
  static const double buttonHeight = 44.0;
  static const double buttonRadius = 12.0;

  // Typography
  static const double fontSizeTitle = 36.0;
  static const double fontSizeScore = 28.0;
  static const double fontSizeStats = 18.0;
  static const double fontSizeStatus = 18.0;
  static const double fontSizeButton = 18.0;

  // Line height factor (multiplier for font size)
  static const double lineHeightFactor = 1.2;
}

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
  Function()? onMainMenu;
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

    // Calculate positions using spacing system
    // All positions are relative to screen center for maintainability
    final centerX = game.size.x / 2;
    final centerY = game.size.y / 2;

    // Text style constants for calculating approximate heights
    const titleStyle = TextStyle(
      fontSize: HudSpacing.fontSizeTitle,
      fontWeight: FontWeight.bold,
    );
    const scoreStyle = TextStyle(
      fontSize: HudSpacing.fontSizeScore,
      fontWeight: FontWeight.bold,
    );
    const statsStyle = TextStyle(fontSize: HudSpacing.fontSizeStats);

    // Calculate approximate text heights (fontSize * lineHeight factor)
    final titleHeight = HudSpacing.fontSizeTitle * HudSpacing.lineHeightFactor;
    final scoreHeight = HudSpacing.fontSizeScore * HudSpacing.lineHeightFactor;
    final statsHeight = HudSpacing.fontSizeStats * HudSpacing.lineHeightFactor;

    // Game Over title - positioned above center
    final titleY = centerY - HudSpacing.gameOverTitleSpacing;
    _gameOverText = TextComponent(
      text: 'Game Over!',
      position: Vector2(centerX, titleY),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: titleStyle.copyWith(
          color: const Color(0xFFF59E0B), // Orange/amber
          shadows: const [
            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black87),
          ],
        ),
      ),
    );
    add(_gameOverText);

    // Final Score - positioned below title with consistent spacing
    final scoreY =
        titleY +
        titleHeight / 2 +
        HudSpacing.gameOverScoreSpacing +
        scoreHeight / 2;
    _finalScoreText = TextComponent(
      text: 'Final Score: 0',
      position: Vector2(centerX, scoreY),
      anchor: Anchor.center,
      textRenderer: TextPaint(style: scoreStyle.copyWith(color: Colors.white)),
    );
    add(_finalScoreText);

    // Stats - positioned below score with consistent spacing
    final statsY =
        scoreY +
        scoreHeight / 2 +
        HudSpacing.gameOverStatsSpacing +
        statsHeight / 2;
    _statsText = TextComponent(
      text: '',
      position: Vector2(centerX, statsY),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: statsStyle.copyWith(color: Colors.white70),
      ),
    );
    add(_statsText);

    // Calculate button area start position
    final firstButtonY =
        statsY +
        statsHeight / 2 +
        HudSpacing.gameOverButtonSpacing +
        HudSpacing.buttonHeight / 2;

    // Save status - positioned below all buttons
    // Calculate from the bottom of the last button
    final lastButtonCenterY =
        firstButtonY +
        (HudSpacing.buttonHeight + HudSpacing.gameOverButtonGap) * 2;
    final lastButtonBottomY = lastButtonCenterY + HudSpacing.buttonHeight / 2;
    final statusTextHeight =
        HudSpacing.fontSizeStatus * HudSpacing.lineHeightFactor;
    final statusY =
        lastButtonBottomY +
        HudSpacing.gameOverStatusSpacing +
        statusTextHeight / 2;
    _saveStatusText = TextComponent(
      text: '',
      position: Vector2(centerX, statusY),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: HudSpacing.fontSizeStatus,
          color: Colors.yellow,
        ),
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

  /// Calculate the Y position of the first button based on spacing system
  double _calculateFirstButtonY() {
    final centerY = game.size.y / 2;
    // Calculate stats Y position using the same logic as onLoad
    final titleY = centerY - HudSpacing.gameOverTitleSpacing;
    final titleHeight = HudSpacing.fontSizeTitle * HudSpacing.lineHeightFactor;
    final scoreHeight = HudSpacing.fontSizeScore * HudSpacing.lineHeightFactor;
    final statsHeight = HudSpacing.fontSizeStats * HudSpacing.lineHeightFactor;

    final scoreY =
        titleY +
        titleHeight / 2 +
        HudSpacing.gameOverScoreSpacing +
        scoreHeight / 2;
    final statsY =
        scoreY +
        scoreHeight / 2 +
        HudSpacing.gameOverStatsSpacing +
        statsHeight / 2;

    // First button center Y
    return statsY +
        statsHeight / 2 +
        HudSpacing.gameOverButtonSpacing +
        HudSpacing.buttonHeight / 2;
  }

  bool handleTap(double x, double y) {
    if (kDebugMode) {
      debugPrint('Hud::handleTap x=$x y=$y gameOver=$_gameOver');
    }
    if (!_gameOver) return false;

    final tapX = x;
    final tapY = y;

    final centerX = game.size.x / 2 - HudSpacing.buttonWidth / 2;
    final firstButtonY = _calculateFirstButtonY() - HudSpacing.buttonHeight / 2;

    // Play again button
    final playAgainRect = Rect.fromLTWH(
      centerX,
      firstButtonY,
      HudSpacing.buttonWidth,
      HudSpacing.buttonHeight,
    );

    // Main menu button
    final mainMenuRect = Rect.fromLTWH(
      centerX,
      firstButtonY + HudSpacing.buttonHeight + HudSpacing.gameOverButtonGap,
      HudSpacing.buttonWidth,
      HudSpacing.buttonHeight,
    );

    // Quit game button
    final quitRect = Rect.fromLTWH(
      centerX,
      firstButtonY +
          (HudSpacing.buttonHeight + HudSpacing.gameOverButtonGap) * 2,
      HudSpacing.buttonWidth,
      HudSpacing.buttonHeight,
    );

    if (kDebugMode) {
      debugPrint('Hud::buttonRects playAgain=$playAgainRect quit=$quitRect');
      debugPrint('Hud::tapPoint ($tapX, $tapY)');
    }

    if (playAgainRect.contains(Offset(tapX, tapY))) {
      if (kDebugMode) {
        debugPrint('Hud::playAgain tapped');
      }
      onPlayAgain?.call();
      return true;
    } else if (mainMenuRect.contains(Offset(tapX, tapY))) {
      if (kDebugMode) {
        debugPrint('Hud::mainMenu tapped');
      }
      onMainMenu?.call();
      return true;
    } else if (quitRect.contains(Offset(tapX, tapY))) {
      if (kDebugMode) {
        debugPrint('Hud::quit tapped');
      }
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

      final centerX = game.size.x / 2 - HudSpacing.buttonWidth / 2;
      final firstButtonY =
          _calculateFirstButtonY() - HudSpacing.buttonHeight / 2;

      // Play Again button
      final playAgainRect = Rect.fromLTWH(
        centerX,
        firstButtonY,
        HudSpacing.buttonWidth,
        HudSpacing.buttonHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          playAgainRect,
          const Radius.circular(HudSpacing.buttonRadius),
        ),
        buttonPaint,
      );

      // Main Menu button
      final mainMenuRect = Rect.fromLTWH(
        centerX,
        firstButtonY + HudSpacing.buttonHeight + HudSpacing.gameOverButtonGap,
        HudSpacing.buttonWidth,
        HudSpacing.buttonHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          mainMenuRect,
          const Radius.circular(HudSpacing.buttonRadius),
        ),
        buttonPaint,
      );

      // Quit button
      final quitRect = Rect.fromLTWH(
        centerX,
        firstButtonY +
            (HudSpacing.buttonHeight + HudSpacing.gameOverButtonGap) * 2,
        HudSpacing.buttonWidth,
        HudSpacing.buttonHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          quitRect,
          const Radius.circular(HudSpacing.buttonRadius),
        ),
        buttonPaint,
      );

      // Button text
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      textPainter.text = TextSpan(
        text: 'Play Again',
        style: TextStyle(
          color: Colors.white,
          fontSize: HudSpacing.fontSizeButton,
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

      textPainter.text = TextSpan(
        text: 'Main Menu',
        style: TextStyle(
          color: Colors.white,
          fontSize: HudSpacing.fontSizeButton,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          mainMenuRect.center.dx - textPainter.width / 2,
          mainMenuRect.center.dy - textPainter.height / 2,
        ),
      );

      textPainter.text = TextSpan(
        text: 'Quit Game',
        style: TextStyle(
          color: Colors.white,
          fontSize: HudSpacing.fontSizeButton,
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
