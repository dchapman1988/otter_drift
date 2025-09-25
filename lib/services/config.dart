import 'dart:io';

const String? envBase = String.fromEnvironment('API_BASE');
const String? envClientId = String.fromEnvironment('CLIENT_ID');
const String? envApiKey = String.fromEnvironment('API_KEY');

String baseUrl() {
  if (envBase != null && envBase!.isNotEmpty) return envBase!;
  if (Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

String clientId() {
  if (envClientId != null && envClientId!.isNotEmpty) return envClientId!;
  return 'game_client_1'; // Default client ID
}

String apiKey() {
  if (envApiKey != null && envApiKey!.isNotEmpty) return envApiKey!;
  return 'your_secret_key_here'; // Default API key - should be overridden in production
}
