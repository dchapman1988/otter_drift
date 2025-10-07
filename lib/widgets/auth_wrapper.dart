import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../services/auth_state_service.dart';
import '../models/player.dart';
import '../screens/auth/login_screen.dart';
import '../screens/profile/profile_screen.dart';
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
    _authStateService.onAuthSuccess(player);
  }

  void _onGuestMode() {
    _authStateService.onGuestMode();
  }

  void _onLogout() async {
    await _authStateService.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
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
              backgroundColor: Color(0xFF1A1A2E),
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
            return OtterGameWrapper(
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

class OtterGameWrapper extends StatelessWidget {
  final AuthStateService authStateService;
  final VoidCallback onLogout;

  const OtterGameWrapper({
    Key? key,
    required this.authStateService,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Player?>(
      stream: authStateService.playerStream,
      initialData: authStateService.currentPlayer,
      builder: (context, snapshot) {
        final player = snapshot.data;
        final isGuest = authStateService.isGuestMode;

        return Scaffold(
          body: Stack(
            children: [
              // Game
              GameWidget<OtterGame>.controlled(
                gameFactory: () => OtterGame(
                  player: player,
                  isGuestMode: isGuest,
                ),
              ),
              
              // Auth status indicator
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isGuest ? Colors.orange : const Color(0xFF4ECDC4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: !isGuest ? () => _showProfile(context) : null,
                        child: Icon(
                          isGuest ? Icons.person_outline : Icons.person,
                          color: isGuest ? Colors.orange : const Color(0xFF4ECDC4),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: !isGuest ? () => _showProfile(context) : null,
                        child: Text(
                          isGuest ? 'Guest' : (player?.displayName ?? 'Player'),
                          style: TextStyle(
                            color: isGuest ? Colors.orange : const Color(0xFF4ECDC4),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isGuest) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showLogoutDialog(context),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProfile(BuildContext context) {
    final player = authStateService.currentPlayer;
    if (player != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            player: player,
            onLogout: onLogout,
          ),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
