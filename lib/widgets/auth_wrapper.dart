import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../services/auth_state_service.dart';
import '../models/player.dart';
import '../screens/auth/login_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/menu/main_menu_screen.dart';
import '../game/otter_game.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthStateService _authStateService = AuthStateService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authStateService.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _onLoginSuccess(Player player) {
    print('DEBUG: AuthWrapper _onLoginSuccess called with player: ${player.username}');
    _authStateService.onAuthSuccess(player);
  }

  void _onGuestMode() {
    _authStateService.onGuestMode();
  }

  void _onLogout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      ),
    );
    
    await _authStateService.onLogout();
    
    // Close loading indicator
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF2C1B15),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
        ),
      );
    }

    return StreamBuilder<AuthState>(
      stream: _authStateService.authStateStream,
      initialData: _authStateService.currentState,
      builder: (context, snapshot) {
        final authState = snapshot.data ?? AuthState.unknown;

        switch (authState) {
          case AuthState.unknown:
            return const Scaffold(
              backgroundColor: Color(0xFF2C1B15),
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                ),
              ),
            );

          case AuthState.unauthenticated:
            return LoginScreen(
              onLoginSuccess: _onLoginSuccess,
              onGuestMode: _onGuestMode,
            );

          case AuthState.authenticated:
          case AuthState.guest:
            return MainMenuWrapper(
              authStateService: _authStateService,
              onLogout: _onLogout,
            );

          default:
            return LoginScreen(
              onLoginSuccess: _onLoginSuccess,
              onGuestMode: _onGuestMode,
            );
        }
      },
    );
  }

  @override
  void dispose() {
    _authStateService.dispose();
    super.dispose();
  }
}

class MainMenuWrapper extends StatelessWidget {
  final AuthStateService authStateService;
  final VoidCallback onLogout;

  const MainMenuWrapper({
    Key? key,
    required this.authStateService,
    required this.onLogout,
  }) : super(key: key);

  void _startGame(BuildContext context, Player? player, bool isGuest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          player: player,
          isGuestMode: isGuest,
          authStateService: authStateService,
          onLogout: onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Player?>(
      stream: authStateService.playerStream,
      initialData: authStateService.currentPlayer,
      builder: (context, snapshot) {
        final player = snapshot.data;
        final isGuest = authStateService.isGuestMode;
        
        print('DEBUG: MainMenuWrapper - player: ${player?.username ?? "null"}, isGuest: $isGuest');
        print('DEBUG: MainMenuWrapper - snapshot.hasData: ${snapshot.hasData}, snapshot.data: ${snapshot.data?.username ?? "null"}');

        return MainMenuScreen(
          player: player,
          isGuestMode: isGuest,
          onStartGame: () => _startGame(context, player, isGuest),
          onLogout: onLogout,
        );
      },
    );
  }
}

class GameScreen extends StatelessWidget {
  final Player? player;
  final bool isGuestMode;
  final AuthStateService authStateService;
  final VoidCallback onLogout;

  const GameScreen({
    Key? key,
    this.player,
    required this.isGuestMode,
    required this.authStateService,
    required this.onLogout,
  }) : super(key: key);

  void _showProfile(BuildContext context) {
    if (player != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            player: player!,
            onLogout: onLogout,
          ),
        ),
      );
    }
  }

  void _showPauseMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1B15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
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
                onPressed: () => Navigator.pop(context),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game
          GameWidget<OtterGame>.controlled(
            gameFactory: () => OtterGame(
              player: player,
              isGuestMode: isGuestMode,
            ),
          ),
          
          // Top bar with player info and menu button
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Menu button
                GestureDetector(
                  onTap: () => _showPauseMenu(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                
                // Player indicator
                GestureDetector(
                  onTap: !isGuestMode ? () => _showProfile(context) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isGuestMode ? Colors.orange : const Color(0xFF4ECDC4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGuestMode ? Icons.person_outline : Icons.person,
                          color: isGuestMode ? Colors.orange : const Color(0xFF4ECDC4),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGuestMode ? 'Guest' : (player?.displayName ?? 'Player'),
                          style: TextStyle(
                            color: isGuestMode ? Colors.orange : const Color(0xFF4ECDC4),
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
