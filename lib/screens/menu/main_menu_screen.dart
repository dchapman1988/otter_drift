import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/player.dart';
import '../../services/player_api_service.dart';
import '../../services/player_auth_service.dart';
import '../../services/auth_state_service.dart';
import '../profile/profile_screen.dart';
import '../leaderboard_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final Player? player;
  final bool isGuestMode;
  final VoidCallback onStartGame;
  final VoidCallback onLogout;

  const MainMenuScreen({
    super.key,
    this.player,
    this.isGuestMode = false,
    required this.onStartGame,
    required this.onLogout,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int? _totalScore;
  int? _gamesPlayed;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(MainMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final playerChanged = oldWidget.player?.id != widget.player?.id;
    final guestModeChanged = oldWidget.isGuestMode != widget.isGuestMode;
    if (playerChanged || guestModeChanged) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    if (widget.isGuestMode || widget.player == null) {
      setState(() {
        _totalScore = null;
        _gamesPlayed = null;
        _isLoadingStats = false;
      });
      return;
    }

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await PlayerApiService.getPlayerStats();
      if (!mounted) return;

      // Extract stats from the known API format: { "player_stats": { "total_score": ..., "games_played": ... } }
      final playerStats = stats?['player_stats'] as Map<String, dynamic>?;
      final totalScore = _parseInt(playerStats?['total_score']);
      final gamesPlayed = _parseInt(playerStats?['games_played']);

      // Use stats from API if available, otherwise fall back to player object
      final updatedTotalScore = totalScore ?? widget.player?.totalScore;
      final updatedGamesPlayed = gamesPlayed ?? widget.player?.gamesPlayed;

      // If we have updated stats and a player object, update the stored player
      if (widget.player != null &&
          (totalScore != null || gamesPlayed != null)) {
        final updatedPlayer = widget.player!.copyWith(
          totalScore: totalScore ?? widget.player!.totalScore,
          gamesPlayed: gamesPlayed ?? widget.player!.gamesPlayed,
        );

        // Update stored player data so it persists across app restarts
        await PlayerAuthService.updateStoredPlayer(updatedPlayer);

        // Update auth state from storage (without fetching from API to avoid stale data)
        // This ensures the player stream is updated with the latest stats
        await AuthStateService().updatePlayerFromStorage();
      }

      setState(() {
        _totalScore = updatedTotalScore;
        _gamesPlayed = updatedGamesPlayed;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      // On error, use values from player object
      setState(() {
        _totalScore = widget.player?.totalScore;
        _gamesPlayed = widget.player?.gamesPlayed;
        _isLoadingStats = false;
      });
    }
  }

  /// Parse a value to int, handling null and string cases
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _showProfile(BuildContext context) {
    if (kDebugMode) {
      debugPrint('MainMenuScreen::_showProfile player=${widget.player}');
    }
    if (widget.player != null) {
      if (kDebugMode) {
        debugPrint('MainMenuScreen::navigating to ProfileScreen');
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfileScreen(player: widget.player!, onLogout: widget.onLogout),
        ),
      );
    } else {
      if (kDebugMode) {
        debugPrint('MainMenuScreen::player is null, cannot show profile');
      }
    }
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1B15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'Quit Game',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit Otter Drift?',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B15),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title Section
                Image.asset(
                  'assets/images/logos/otter_logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Otter Drift',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isGuestMode
                      ? 'Playing as Guest'
                      : 'Welcome, ${widget.player?.displayName ?? "Player"}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: widget.isGuestMode
                        ? Colors.orange
                        : const Color(0xFF66A0C8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                // Player Stats Summary (if authenticated)
                if (!widget.isGuestMode && widget.player != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat(
                          label: 'Total Score',
                          value: _totalScore ?? widget.player?.totalScore,
                          icon: Icons.star,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        _buildQuickStat(
                          label: 'Games',
                          value: _gamesPlayed ?? widget.player?.gamesPlayed,
                          icon: Icons.games,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Main Menu Buttons
                ElevatedButton.icon(
                  onPressed: widget.onStartGame,
                  icon: const Icon(Icons.play_arrow, size: 32),
                  label: const Text(
                    'Start Game',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5E4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF7B5E4F).withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),

                // Profile Button (only for authenticated users)
                if (!widget.isGuestMode) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      if (kDebugMode) {
                        debugPrint('MainMenuScreen::profile button pressed');
                      }
                      _showProfile(context);
                    },
                    icon: const Icon(Icons.person),
                    label: const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF66A0C8),
                      side: const BorderSide(
                        color: Color(0xFF66A0C8),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Leaderboard Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.leaderboard),
                  label: const Text(
                    'Leaderboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white38, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Settings/Quit Button
                OutlinedButton.icon(
                  onPressed: () => _showQuitDialog(context),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text(
                    'Quit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign Out Button (bottom)
                if (!widget.isGuestMode) ...[
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2C1B15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Are you sure you want to sign out?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onLogout();
                              },
                              child: const Text(
                                'Sign Out',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.withValues(alpha: 0.7),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Version info
                Text(
                  'Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat({
    required String label,
    required int? value,
    required IconData icon,
  }) {
    final displayValue = _isLoadingStats && value == null
        ? '...'
        : (value ?? 0).toString();

    return Column(
      children: [
        Icon(icon, color: const Color(0xFF66A0C8), size: 24),
        const SizedBox(height: 8),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
