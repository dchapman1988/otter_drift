import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/otter_game.dart';
import 'services/quick_test.dart';

void main() {
  // Test security configuration on startup
  try {
    QuickTest.testSecurityConfig();
  } catch (e) {
    print('Security configuration test failed: $e');
    // Continue with app startup even if security test fails
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
      home: const GameScreen(),
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
