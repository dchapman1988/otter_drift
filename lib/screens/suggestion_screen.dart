import 'package:flutter/material.dart';
import '../services/suggestion_service.dart';
import '../services/player_auth_service.dart';
import 'package:dio/dio.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;
  Map<String, List<String>>? _fieldErrors;
  bool _showSuccessMessage = false;

  static const int _minLength = 3;
  static const int _maxLength = 1000;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _currentLength => _noteController.text.length;
  bool get _isValid => _currentLength >= _minLength && _currentLength <= _maxLength;

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _fieldErrors = null;
      _showSuccessMessage = false;
    });

    try {
      final note = _noteController.text.trim();

      await SuggestionService.submitSuggestion(note: note);

      // Success - clear form and show success message
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _showSuccessMessage = true;
        });

        // Clear the form
        _noteController.clear();

        // Hide success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showSuccessMessage = false;
            });
          }
        });
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.getMessage();
          _fieldErrors = {};
          e.errors.forEach((field, errors) {
            _fieldErrors![field] = errors is List
                ? errors.map((e) => e.toString()).toList()
                : [errors.toString()];
          });
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (e.response?.statusCode == 422) {
            // Handle validation errors from DioException
            final errors = e.response?.data['errors'] as Map<String, dynamic>?;
            if (errors != null) {
              _fieldErrors = {};
              errors.forEach((field, errorList) {
                if (errorList is List) {
                  _fieldErrors![field] =
                      errorList.map((e) => e.toString()).toList();
                } else {
                  _fieldErrors![field] = [errorList.toString()];
                }
              });
              _errorMessage = ValidationException(errors).getMessage();
            } else {
              _errorMessage = 'Validation failed. Please check your input.';
            }
          } else {
            _errorMessage = 'Network error: ${e.message ?? "Unable to submit suggestion. Please check your connection."}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
      }
    }
  }

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
          'Submit Suggestion',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Message
              if (_showSuccessMessage)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Suggestion submitted successfully! Thank you for your feedback.',
                          style: TextStyle(
                            color: Colors.green[200],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Error Message
              if (_errorMessage != null && !_showSuccessMessage)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[200],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4ECDC4),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Share your ideas, feedback, or suggestions to help improve Otter Drift!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Suggestion Label
              const Text(
                'Your Suggestion',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Suggestion Text Field
              TextFormField(
                controller: _noteController,
                maxLines: 8,
                maxLength: _maxLength,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your suggestion here (3-1000 characters)...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4ECDC4),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  errorText: _fieldErrors?['note']?.isNotEmpty == true
                      ? _fieldErrors!['note']!.first
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Suggestion cannot be empty';
                  }
                  final trimmed = value.trim();
                  if (trimmed.length < _minLength) {
                    return 'Suggestion must be at least $_minLength characters';
                  }
                  if (trimmed.length > _maxLength) {
                    return 'Suggestion must be no more than $_maxLength characters';
                  }
                  return null;
                },
                onChanged: (_) {
                  setState(() {
                    // Clear field errors when user types
                    _fieldErrors?.remove('note');
                    if (_fieldErrors?.isEmpty == true) {
                      _fieldErrors = null;
                    }
                    _errorMessage = null;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Character Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentLength < _minLength
                        ? 'Minimum $_minLength characters required'
                        : '${_maxLength - _currentLength} characters remaining',
                    style: TextStyle(
                      color: _isValid
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.orange.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$_currentLength / $_maxLength',
                    style: TextStyle(
                      color: _isValid
                          ? const Color(0xFF4ECDC4)
                          : Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                onPressed: (_isSubmitting || !_isValid) ? null : _submitSuggestion,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Suggestion',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid
                      ? const Color(0xFF4ECDC4)
                      : Colors.grey.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isValid ? 4 : 0,
                ),
              ),

              const SizedBox(height: 16),

              // User Info (if authenticated)
              FutureBuilder<bool>(
                future: PlayerAuthService.isAuthenticated(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return FutureBuilder(
                      future: PlayerAuthService.getCurrentPlayer(),
                      builder: (context, playerSnapshot) {
                        if (playerSnapshot.hasData && playerSnapshot.data != null) {
                          final player = playerSnapshot.data!;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF4ECDC4),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Submitting as: ${player.username}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_off_outlined,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Submitting as guest',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


