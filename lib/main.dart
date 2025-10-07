import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/otter_game.dart';
import 'services/quick_test.dart';
import 'services/player_auth_debug.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test security configuration on startup
  try {
    QuickTest.testSecurityConfig();
  } catch (e) {
    print('Security configuration test failed: $e');
    // Continue with app startup even if security test fails
  }
  
  // Debug: Check player auth status on startup
  try {
    await PlayerAuthDebug.runAllChecks();
  } catch (e) {
    print('Player auth debug check failed: $e');
  }
  
  runApp(const OtterDriftApp());
}

class OtterDriftApp extends StatelessWidget {
  const OtterDriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otter Drift',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<OtterGame>.controlled(
        gameFactory: OtterGame.new,
      ),
    );
  }
}
