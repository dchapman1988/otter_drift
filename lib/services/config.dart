import 'security_config.dart';

// Legacy functions for backward compatibility
// These now delegate to SecurityConfig for enhanced security

String baseUrl() {
  return SecurityConfig.getBaseUrl();
}

String clientId() {
  return SecurityConfig.getClientId();
}

String apiKey() {
  return SecurityConfig.getApiKey();
}
