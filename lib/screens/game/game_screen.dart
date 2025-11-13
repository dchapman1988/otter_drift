import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../../services/auth_state_service.dart';
import '../../models/player.dart';
import '../../screens/profile/profile_screen.dart';
import '../../game/otter_game.dart';

/// GameScreen is responsible for displaying the game and managing game-related UI.
/// It handles pause menu, profile navigation, and delegates game logic to OtterGame.
class GameScreen extends StatefulWidget {
  final Player? player;
  final bool isGuestMode;
  final AuthStateService authStateService;
  final VoidCallback onLogout;

  const GameScreen({
    super.key,
    this.player,
    required this.isGuestMode,
    required this.authStateService,
    required this.onLogout,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late OtterGame _game;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _game = OtterGame(player: widget.player, isGuestMode: widget.isGuestMode);
  }

  void _showProfile(BuildContext context) {
    if (widget.player != null) {
      // Pause game when navigating to profile
      _pauseGame();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfileScreen(player: widget.player!, onLogout: widget.onLogout),
        ),
      ).then((_) {
        // Resume game when returning from profile
        if (mounted && _isPaused) {
          _resumeGame();
        }
      });
    }
  }

  void _pauseGame() {
    if (!_isPaused) {
      _game.pauseGame();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeGame() {
    if (_isPaused) {
      _game.resumeGame();
      setState(() {
        _isPaused = false;
      });
    }
  }

  void _showPauseMenu(BuildContext context) {
    // Pause the game
    _pauseGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1B15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        title: const Text(
          'Paused',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resumeGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Resume'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Resume before navigating to avoid leaving game in paused state
                  _resumeGame();
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to menu
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                ),
                child: const Text('Main Menu'),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      // If dialog was dismissed without resume button, resume game
      if (mounted && _isPaused) {
        _resumeGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game
          GameWidget<OtterGame>.controlled(gameFactory: () => _game),

          // Top bar with player info and menu button
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pause button
                GestureDetector(
                  onTap: () => _showPauseMenu(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Player indicator
                GestureDetector(
                  onTap: !widget.isGuestMode
                      ? () => _showProfile(context)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isGuestMode
                            ? Colors.orange
                            : const Color(0xFF4ECDC4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isGuestMode
                              ? Icons.person_outline
                              : Icons.person,
                          color: widget.isGuestMode
                              ? Colors.orange
                              : const Color(0xFF4ECDC4),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isGuestMode
                              ? 'Guest'
                              : (widget.player?.displayName ?? 'Player'),
                          style: TextStyle(
                            color: widget.isGuestMode
                                ? Colors.orange
                                : const Color(0xFF4ECDC4),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
