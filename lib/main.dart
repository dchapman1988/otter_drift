import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/otter_game.dart';

void main() {
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
