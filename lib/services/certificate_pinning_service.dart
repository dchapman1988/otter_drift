import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'security_config.dart';
import 'secure_logger.dart';

/// Service for handling certificate pinning
class CertificatePinningService {
  
  /// Create a certificate pinning interceptor for Dio
  static Interceptor createPinningInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final host = _extractHost(options.uri);
          final pins = SecurityConfig.getCertificatePins(host);
          
          if (pins.isNotEmpty) {
            SecureLogger.logSecurity('Applying certificate pinning for $host', data: {
              'pins': pins,
              'url': options.uri.toString(),
            });
            
            // Apply certificate pinning
            await _applyCertificatePinning(options, pins);
          } else {
            SecureLogger.logDebug('No certificate pins configured for $host');
          }
          
          handler.next(options);
        } catch (e) {
          SecureLogger.logError('Certificate pinning failed', error: e);
          handler.reject(DioException(
            requestOptions: options,
            error: 'Certificate pinning failed: $e',
            type: DioExceptionType.unknown,
          ));
        }
      },
    );
  }
  
  /// Apply certificate pinning to a request
  static Future<void> _applyCertificatePinning(
    RequestOptions options, 
    List<String> pins
  ) async {
    try {
      // For HTTP requests, we can't pin certificates
      if (options.uri.scheme == 'http') {
        SecureLogger.logSecurity('Skipping certificate pinning for HTTP request');
        return;
      }
      
      // For HTTPS requests, apply certificate pinning
      if (options.uri.scheme == 'https') {
        await _pinCertificate(options.uri.toString(), pins);
      }
    } catch (e) {
      SecureLogger.logError('Failed to apply certificate pinning', error: e);
      rethrow;
    }
  }
  
  /// Pin certificate for a specific URL
  static Future<void> _pinCertificate(String url, List<String> pins) async {
    try {
      // For now, we'll implement a basic certificate validation
      // In a production app, you would use a proper certificate pinning library
      // or implement custom certificate validation
      
      final uri = Uri.parse(url);
      final host = uri.host;
      final port = uri.port;
      
      // Connect to the server and get the certificate
      final socket = await SecureSocket.connect(host, port);
      final certificate = socket.peerCertificate;
      
      if (certificate == null) {
        throw CertificatePinningException('No certificate found for $url');
      }
      
      // Get the certificate's SHA256 fingerprint
      final fingerprint = _getCertificateFingerprint(certificate);
      final fingerprintString = 'sha256/$fingerprint';
      
      // Check if the fingerprint matches any of the pinned certificates
      final isPinned = pins.any((pin) => pin == fingerprintString);
      
      if (!isPinned) {
        SecureLogger.logSecurity('Certificate fingerprint mismatch for $url', data: {
          'expected': pins,
          'actual': fingerprintString,
        });
        throw CertificatePinningException('Certificate pinning verification failed for $url');
      }
      
      SecureLogger.logSecurity('Certificate pinning verification successful for $url');
      await socket.close();
    } catch (e) {
      SecureLogger.logError('Certificate pinning verification failed for $url', error: e);
      rethrow;
    }
  }
  
  /// Extract host from URI
  static String _extractHost(Uri uri) {
    return '${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
  }
  
  /// Get SHA256 fingerprint of a certificate
  static String _getCertificateFingerprint(X509Certificate certificate) {
    try {
      // Get the certificate's DER encoding
      final derBytes = certificate.der;
      
      // Calculate SHA256 hash
      final hash = sha256.convert(derBytes);
      
      // Convert to base64
      return base64Encode(hash.bytes);
    } catch (e) {
      SecureLogger.logError('Failed to calculate certificate fingerprint', error: e);
      throw CertificatePinningException('Failed to calculate certificate fingerprint: $e');
    }
  }
  
  /// Validate certificate pins format
  static bool validatePinFormat(String pin) {
    // Validate SHA256 pin format: sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
    final regex = RegExp(r'^sha256/[A-Za-z0-9+/]{43}=$');
    return regex.hasMatch(pin);
  }
  
  /// Get certificate fingerprint for a host (for development/setup)
  static Future<String?> getCertificateFingerprint(String host, {int port = 443}) async {
    try {
      SecureLogger.logDebug('Getting certificate fingerprint for $host:$port');
      
      final socket = await SecureSocket.connect(host, port);
      final certificate = socket.peerCertificate;
      
      if (certificate == null) {
        SecureLogger.logError('No certificate found for $host:$port');
        return null;
      }
      
      // Get SHA256 fingerprint
      final fingerprint = _getCertificateFingerprint(certificate);
      final fingerprintString = 'sha256/$fingerprint';
      
      SecureLogger.logInfo('Certificate fingerprint for $host:$port: $fingerprintString');
      
      await socket.close();
      return fingerprintString;
    } catch (e) {
      SecureLogger.logError('Failed to get certificate fingerprint for $host:$port', error: e);
      return null;
    }
  }
  
  /// Test certificate pinning for a specific host
  static Future<bool> testCertificatePinning(String host, {int port = 443}) async {
    try {
      final pins = SecurityConfig.getCertificatePins(host);
      
      if (pins.isEmpty) {
        SecureLogger.logInfo('No certificate pins configured for $host');
        return true; // No pins means no verification needed
      }
      
      final url = 'https://$host${port != 443 ? ':$port' : ''}';
      await _pinCertificate(url, pins);
      
      SecureLogger.logInfo('Certificate pinning test passed for $host');
      return true;
    } catch (e) {
      SecureLogger.logError('Certificate pinning test failed for $host', error: e);
      return false;
    }
  }
}

/// Exception for certificate pinning failures
class CertificatePinningException implements Exception {
  final String message;
  
  const CertificatePinningException(this.message);
  
  @override
  String toString() => 'CertificatePinningException: $message';
}
