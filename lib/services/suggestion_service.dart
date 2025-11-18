import 'package:dio/dio.dart';
import 'api_service.dart';
import 'player_auth_service.dart';
import 'secure_logger.dart';

/// Service for submitting suggestions to the backend API
class SuggestionService {
  /// Submit a suggestion to the backend
  ///
  /// [note] - The suggestion text (required, 3-1000 characters)
  /// [playerName] - Optional player username. If null and user is authenticated,
  ///                will automatically include the current player's username.
  ///
  /// Returns a Map containing the suggestion data on success
  /// Throws [ValidationException] for validation errors (422)
  /// Throws [DioException] for network errors
  static Future<Map<String, dynamic>> submitSuggestion({
    required String note,
    String? playerName,
  }) async {
    try {
      SecureLogger.logDebug(
        'Submitting suggestion (note length: ${note.length})',
      );

      // If playerName is not provided, check if user is authenticated
      String? resolvedPlayerName = playerName;
      if (resolvedPlayerName == null) {
        final isAuthenticated = await PlayerAuthService.isAuthenticated();
        if (isAuthenticated) {
          final player = await PlayerAuthService.getCurrentPlayer();
          resolvedPlayerName = player?.username;
          SecureLogger.logDebug(
            'User is authenticated, including player_name: $resolvedPlayerName',
          );
        } else {
          SecureLogger.logDebug(
            'User is not authenticated, submitting as guest',
          );
        }
      }

      // Build request payload
      final suggestionData = <String, dynamic>{'note': note};

      // Only include player_name if it's provided
      if (resolvedPlayerName != null && resolvedPlayerName.isNotEmpty) {
        suggestionData['player_name'] = resolvedPlayerName;
      }

      final requestData = {'suggestion': suggestionData};

      SecureLogger.logRequest('POST', '/api/v1/suggestions', body: requestData);

      final response = await ApiService.post(
        '/api/v1/suggestions',
        data: requestData,
      );

      SecureLogger.logResponse(
        response.statusCode ?? 0,
        '/api/v1/suggestions',
        body: response.data,
      );

      if (response.statusCode == 201) {
        SecureLogger.logDebug('Suggestion submitted successfully');
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 422) {
        // Handle validation errors
        final errors = response.data['errors'] as Map<String, dynamic>?;
        SecureLogger.logError('Suggestion validation failed', error: errors);
        throw ValidationException(errors ?? {});
      } else {
        SecureLogger.logError('Unexpected status code: ${response.statusCode}');
        throw Exception('Failed to submit suggestion: ${response.statusCode}');
      }
    } on DioException catch (e) {
      SecureLogger.logError('Network error submitting suggestion', error: e);

      // Handle 422 validation errors from DioException
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        throw ValidationException(errors ?? {});
      }

      // Re-throw DioException for other network errors
      rethrow;
    } catch (e) {
      // Re-throw ValidationException as-is
      if (e is ValidationException) {
        rethrow;
      }

      SecureLogger.logError('Unexpected error submitting suggestion', error: e);
      throw Exception('Failed to submit suggestion: $e');
    }
  }
}

/// Exception thrown when suggestion validation fails
class ValidationException implements Exception {
  final Map<String, dynamic> errors;

  const ValidationException(this.errors);

  /// Get error messages for a specific field
  List<String>? getFieldErrors(String field) {
    final fieldErrors = errors[field];
    if (fieldErrors == null) return null;

    if (fieldErrors is List) {
      return fieldErrors.map((e) => e.toString()).toList();
    } else if (fieldErrors is String) {
      return [fieldErrors];
    }

    return null;
  }

  /// Get all error messages as a flat list
  List<String> getAllErrors() {
    final allErrors = <String>[];
    errors.forEach((field, errorList) {
      if (errorList is List) {
        for (final error in errorList) {
          allErrors.add('${field.replaceAll('_', ' ')}: ${error.toString()}');
        }
      } else if (errorList is String) {
        allErrors.add('${field.replaceAll('_', ' ')}: $errorList');
      }
    });
    return allErrors;
  }

  /// Get a user-friendly error message
  String getMessage() {
    final allErrors = getAllErrors();
    if (allErrors.isEmpty) {
      return 'Validation failed';
    }
    return allErrors.join('\n');
  }

  @override
  String toString() => getMessage();
}
