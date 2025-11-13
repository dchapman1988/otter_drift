import 'package:flutter/material.dart';
import 'widgets/auth_wrapper.dart';
import 'services/game_session_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameSessionSyncService.instance.initialize();

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
