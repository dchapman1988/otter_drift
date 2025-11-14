import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/game/game_screen.dart';
import 'package:flutter_frontend/services/auth_state_service.dart';
import 'package:flutter_frontend/models/player.dart';

void main() {
  group('GameScreen Widget Tests', () {
    late AuthStateService authStateService;
    late VoidCallback onLogout;

    setUp(() {
      authStateService = AuthStateService();
      onLogout = () {};
    });

    testWidgets('renders game screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            player: null,
            isGuestMode: true,
            authStateService: authStateService,
            onLogout: onLogout,
          ),
        ),
      );

      // Game should be rendered
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('shows player indicator for guest mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            player: null,
            isGuestMode: true,
            authStateService: authStateService,
            onLogout: onLogout,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Guest indicator should be visible
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('shows player name for authenticated user', (
      WidgetTester tester,
    ) async {
      final player = Player(
        id: 123,
        username: 'testuser',
        email: 'test@example.com',
        displayName: 'Test User',
        totalScore: 0,
        gamesPlayed: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            player: player,
            isGuestMode: false,
            authStateService: authStateService,
            onLogout: onLogout,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Player name should be visible (displayName or username)
      expect(find.textContaining('Test User'), findsWidgets);
    });
  });
}
