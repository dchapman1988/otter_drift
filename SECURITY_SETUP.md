# 🔒 Secure JWT Authentication Setup

This document provides comprehensive instructions for setting up secure JWT authentication with advanced security features.

## 🚀 Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Build with Your API Key

```bash
# Development
flutter run --dart-define=API_KEY=your_development_api_key_here

# Production
flutter build apk --dart-define=API_KEY=your_production_api_key_here
```

## 🔧 Configuration

### Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `API_KEY` | ✅ Yes | 64-character hex API key | `your_64_character_hex_api_key_here` |
| `CLIENT_ID` | ❌ No | Client identifier (default: `game_client_1`) | `game_client_1` |
| `API_BASE` | ❌ No | Base URL (auto-detected) | `https://api.yourdomain.com` |

### Build Commands

```bash
# Development with custom client ID
flutter run --dart-define=API_KEY=your_development_api_key_here --dart-define=CLIENT_ID=game_client_1

# Staging
flutter build apk --dart-define=API_KEY=staging_api_key_here --dart-define=CLIENT_ID=staging_client

# Production
flutter build apk --dart-define=API_KEY=production_api_key_here --dart-define=CLIENT_ID=production_client
```

## 🛡️ Security Features

### 1. Build-Time Validation

The app validates credentials at startup and will fail to build/run if:
- API key is missing
- API key is not 64 characters
- API key is not valid hexadecimal
- Client ID is invalid format

### 2. Certificate Pinning

Configure certificate pins in `lib/services/security_config.dart`:

```dart
static const Map<String, List<String>> _certificatePins = {
  'localhost:3000': [
    'sha256/YOUR_LOCALHOST_CERTIFICATE_PIN_HERE',
  ],
  'your-production-domain.com': [
    'sha256/YOUR_PRODUCTION_CERTIFICATE_PIN_HERE',
  ],
};
```

#### Getting Certificate Pins

```bash
# For localhost (development)
openssl s_client -connect localhost:3000 -servername localhost | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64

# For production domain
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

### 3. Secure Logging

- **Production**: Sensitive data is automatically masked
- **Development**: Full logging for debugging
- **Automatic masking**: API keys, JWT tokens, authorization headers

### 4. Retry Logic

- **Exponential backoff**: 1s, 2s, 4s delays
- **Jitter**: ±25% randomization to prevent thundering herd
- **Smart retry**: Only retries on network errors and 5xx responses
- **Max attempts**: 3 attempts per request

### 5. Timeout Configuration

- **Connect timeout**: 10 seconds
- **Receive timeout**: 15 seconds
- **Send timeout**: 10 seconds

## 📱 Usage Examples

### Basic Usage (No Changes Required)

```dart
import 'package:your_app/services/backend.dart';

// Your existing code works exactly the same!
final result = await BackendService.saveScore(
  sessionId: 'session_123',
  playerName: 'Player1',
  seed: 42,
  startedAt: DateTime.now().subtract(Duration(minutes: 5)),
  endedAt: DateTime.now(),
  finalScore: 1500,
  gameDuration: 300.0,
  maxSpeedReached: 15.5,
  obstaclesAvoided: 12,
  liliesCollected: 8,
);
```

### Security Management

```dart
import 'package:your_app/services/backend.dart';
import 'package:your_app/services/security_config.dart';

// Check authentication status
final isAuth = await BackendService.isAuthenticated();

// Get environment info (debug mode only)
if (SecurityConfig.isDebugMode()) {
  final envInfo = SecurityConfig.getEnvironmentInfo();
  print('Environment: $envInfo');
}

// Manual authentication
final authSuccess = await BackendService.authenticate();

// Logout
await BackendService.logout();
```

### Testing Security Features

```dart
import 'package:your_app/services/certificate_pinning_service.dart';

// Test certificate pinning
final pinningSuccess = await CertificatePinningService.testCertificatePinning('yourdomain.com');
print('Certificate pinning test: $pinningSuccess');

// Get certificate fingerprint (for setup)
final fingerprint = await CertificatePinningService.getCertificateFingerprint('yourdomain.com');
print('Certificate fingerprint: $fingerprint');
```

## 🔍 Debugging

### Enable Debug Logging

Debug logging is automatically enabled in debug builds. You'll see:

```
[SecureLogger] [DEBUG] 2024-01-15T10:30:00.000Z: User is authenticated with valid token
[SecureLogger] [AUTH] 2024-01-15T10:30:01.000Z: Starting authentication process
[SecureLogger] [REQUEST] 2024-01-15T10:30:02.000Z: POST https://api.example.com/api/v1/auth/login
[SecureLogger] [RESPONSE] 2024-01-15T10:30:03.000Z: 200 https://api.example.com/api/v1/auth/login
```

### Production Logging

In production builds, sensitive data is automatically masked:

```
[SecureLogger] [AUTH] 2024-01-15T10:30:00.000Z: Starting authentication process
[SecureLogger] [REQUEST] 2024-01-15T10:30:01.000Z: POST https://api.example.com/api/v1/auth/login
[SecureLogger] [REQUEST] Data: {"client_id":"game_client_1","api_key":"78f28fff***********5ee0"}
```

## 🚨 Security Best Practices

### 1. API Key Management

- ✅ **DO**: Use `--dart-define` for build-time injection
- ✅ **DO**: Use different keys for dev/staging/production
- ❌ **DON'T**: Hardcode API keys in source code
- ❌ **DON'T**: Store API keys in version control

### 2. Certificate Pinning

- ✅ **DO**: Pin certificates for production domains
- ✅ **DO**: Update pins when certificates are renewed
- ✅ **DO**: Test pinning in staging environment first
- ❌ **DON'T**: Pin certificates for localhost in production

### 3. Logging

- ✅ **DO**: Review logs for security events
- ✅ **DO**: Monitor authentication failures
- ❌ **DON'T**: Log sensitive data in production
- ❌ **DON'T**: Ship debug logs to production

### 4. Network Security

- ✅ **DO**: Use HTTPS in production
- ✅ **DO**: Implement proper timeout values
- ✅ **DO**: Handle network errors gracefully
- ❌ **DON'T**: Ignore certificate errors

## 🛠️ Troubleshooting

### Common Issues

#### 1. Build Fails with "API_KEY environment variable is required"

**Solution**: Provide the API key at build time:
```bash
flutter run --dart-define=API_KEY=your_development_api_key_here
```

#### 2. "API key must be exactly 64 characters long"

**Solution**: Ensure your API key is exactly 64 hexadecimal characters:
```bash
# Check your API key length
echo "your_development_api_key_here" | wc -c
# Should output 65 (64 chars + newline)
```

#### 3. Certificate Pinning Fails

**Solution**: 
1. Get the correct certificate pin for your domain
2. Update the pin in `security_config.dart`
3. Test with `CertificatePinningService.testCertificatePinning()`

#### 4. Authentication Fails

**Solution**:
1. Check your Rails backend is running
2. Verify the API key is correct
3. Check network connectivity
4. Review logs for detailed error information

### Debug Commands

```bash
# Test authentication endpoint
flutter run --dart-define=API_KEY=your_key_here
# Then call: BackendService.testAuthentication()

# Check environment configuration
flutter run --dart-define=API_KEY=your_key_here
# Then call: SecurityConfig.getEnvironmentInfo()

# Test certificate pinning
flutter run --dart-define=API_KEY=your_key_here
# Then call: CertificatePinningService.testCertificatePinning('yourdomain.com')
```

## 📋 Production Checklist

- [ ] API key configured via `--dart-define`
- [ ] Certificate pins configured for production domain
- [ ] Different API keys for dev/staging/production
- [ ] HTTPS enabled in production
- [ ] Timeout values appropriate for your network
- [ ] Error handling implemented in UI
- [ ] Logging reviewed for sensitive data
- [ ] Security testing completed

## 🔄 Migration from Previous Version

If you're upgrading from the basic JWT implementation:

1. **No code changes required** - existing API calls work the same
2. **Update build commands** - add `--dart-define=API_KEY=your_key`
3. **Configure certificate pins** - update `security_config.dart`
4. **Test thoroughly** - verify all functionality works with new security features

The enhanced security is completely transparent to your existing code!
