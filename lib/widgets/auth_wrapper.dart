import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_state_service.dart';
import '../models/player.dart';
import '../screens/auth/login_screen.dart';
import '../screens/menu/main_menu_screen.dart';
import '../screens/game/game_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

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
    if (kDebugMode) {
      debugPrint('AuthWrapper::_onLoginSuccess player=${player.username}');
    }
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
    super.key,
    required this.authStateService,
    required this.onLogout,
  });

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
