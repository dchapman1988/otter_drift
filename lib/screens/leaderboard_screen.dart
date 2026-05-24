import 'package:flutter/material.dart';
import '../widgets/leaderboard_widget.dart';
import '../widgets/banner_ad_widget.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1B15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Global Leaderboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              child: LeaderboardWidget(
                initialLimit: 100,
                showLimitSelector: true,
              ),
            ),
            // Banner Ad at bottom with proper spacing
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}
