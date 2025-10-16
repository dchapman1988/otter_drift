import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../models/player_profile.dart';
import '../../services/player_api_service.dart';
import '../../services/secure_logger.dart';

class EditProfileScreen extends StatefulWidget {
  final Player player;
  final Function(Player) onProfileUpdated;

  const EditProfileScreen({
    Key? key,
    required this.player,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _favoriteOtterFactController = TextEditingController();
  final _titleController = TextEditingController();
  final _profileBannerUrlController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _validationErrors;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final profile = widget.player.profile;
    _bioController.text = profile?.bio ?? '';
    _favoriteOtterFactController.text = profile?.favoriteOtterFact ?? '';
    _titleController.text = profile?.title ?? '';
    _profileBannerUrlController.text = profile?.profileBannerUrl ?? '';
    _locationController.text = profile?.location ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    _favoriteOtterFactController.dispose();
    _titleController.dispose();
    _profileBannerUrlController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _getFieldError(String fieldName) {
    if (_validationErrors == null) return null;
    
    final errors = _validationErrors![fieldName];
    if (errors is List && errors.isNotEmpty) {
      return errors.first;
    } else if (errors is String) {
      return errors;
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _validationErrors = null;
    });

    try {
      final profile = PlayerProfile(
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        favoriteOtterFact: _favoriteOtterFactController.text.trim().isEmpty 
            ? null 
            : _favoriteOtterFactController.text.trim(),
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        profileBannerUrl: _profileBannerUrlController.text.trim().isEmpty 
            ? null 
            : _profileBannerUrlController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
      );

      final updatedPlayer = await PlayerApiService.updatePlayerProfile(
        profile: profile,
      );

      if (updatedPlayer != null) {
        SecureLogger.logDebug('Profile updated successfully');
        widget.onProfileUpdated(updatedPlayer);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFF4ECDC4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _validationErrors = {'general': ['Failed to update profile. Please try again.']};
        });
      }
    } catch (e) {
      SecureLogger.logError('Error updating profile', error: e);
      setState(() {
        _validationErrors = {'general': ['An error occurred while updating your profile.']};
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // General error message
              if (_validationErrors?['general'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationErrors!['general'] is List
                              ? _validationErrors!['general'].first
                              : _validationErrors!['general'].toString(),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bio Field
              _buildSectionTitle('Bio'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                  ),
                  errorText: _getFieldError('bio'),
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),

              const SizedBox(height: 24),

              // Favorite Otter Fact Field
              _buildSectionTitle('Favorite Otter Fact'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _favoriteOtterFactController,
                maxLines: 2,
                maxLength: 200,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Share an interesting fact about otters...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                  ),
                  errorText: _getFieldError('favorite_otter_fact'),
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),

              const SizedBox(height: 24),

              // Title Field
              _buildSectionTitle('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                maxLength: 50,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., "Otter Enthusiast", "River Explorer"',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                  ),
                  errorText: _getFieldError('title'),
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),

              const SizedBox(height: 24),

              // Location Field
              _buildSectionTitle('Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                maxLength: 100,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., "Seattle, WA", "Portland, OR"',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                  ),
                  errorText: _getFieldError('location'),
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),

              const SizedBox(height: 24),

              // Profile Banner URL Field
              _buildSectionTitle('Profile Banner URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _profileBannerUrlController,
                maxLength: 500,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://example.com/banner.jpg',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4ECDC4)),
                  ),
                  errorText: _getFieldError('profile_banner_url'),
                  counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasAbsolutePath) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
