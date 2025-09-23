import 'dart:io';

const String? envBase = String.fromEnvironment('API_BASE');

String baseUrl() {
  if (envBase != null && envBase!.isNotEmpty) return envBase!;
  if (Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}
