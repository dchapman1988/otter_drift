import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  Player? _player;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  Map<String, dynamic>? _validationErrors;
  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarName;
  String? _selectedAvatarPath;
  String? _avatarError;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _populateFormFromPlayer(_player);
    _loadProfileData();
  }

  void _populateFormFromPlayer(Player? player) {
    final profile = player?.profile;
    _bioController.text = profile?.bio ?? '';
    _favoriteOtterFactController.text = profile?.favoriteOtterFact ?? '';
    _titleController.text = profile?.title ?? '';
    _profileBannerUrlController.text = profile?.profileBannerUrl ?? '';
    _locationController.text = profile?.location ?? '';
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the latest player profile data from the backend
      final player = await PlayerApiService.getPlayerProfile();
      
      if (mounted && player != null) {
        _populateFormFromPlayer(player);

        setState(() {
          _player = player;
          _isLoading = false;
        });
      }
    } catch (e) {
      SecureLogger.logError('Failed to load profile data', error: e);
      if (mounted) {
        // Fallback to using the passed player data if available
        _populateFormFromPlayer(widget.player);
        
        setState(() {
          _player = widget.player;
          _isLoading = false;
          _validationErrors = {'general': ['Failed to load latest profile data. Showing cached data.']};
        });
      }
    }
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

  Future<void> _pickAvatar() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() {
          _avatarError = 'Please choose an image smaller than 5MB.';
          _selectedAvatarBytes = null;
          _selectedAvatarName = null;
          _selectedAvatarPath = null;
        });
        return;
      }

      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarName = pickedFile.name;
        _selectedAvatarPath = pickedFile.path;
        _avatarError = null;
      });
    } catch (e) {
      SecureLogger.logError('Failed to pick avatar image', error: e);
      setState(() {
        _avatarError = 'Failed to open image picker. Please try again.';
      });
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedAvatarBytes == null || _selectedAvatarName == null) {
      setState(() {
        _avatarError = 'Please choose an image before uploading.';
      });
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
      _avatarError = null;
    });

    try {
      final mimeType = lookupMimeType(
        _selectedAvatarPath ?? _selectedAvatarName!,
        headerBytes: _selectedAvatarBytes,
      );

      final updatedPlayer = await PlayerApiService.uploadPlayerAvatar(
        fileBytes: _selectedAvatarBytes!,
        filename: _selectedAvatarName!,
        mimeType: mimeType,
      );

      if (updatedPlayer != null) {
        widget.onProfileUpdated(updatedPlayer);

        if (mounted) {
          setState(() {
            _player = updatedPlayer;
            _selectedAvatarBytes = null;
            _selectedAvatarName = null;
            _selectedAvatarPath = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated successfully!'),
              backgroundColor: Color(0xFF4ECDC4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _avatarError = 'Failed to upload avatar. Please try again.';
        });
      }
    } catch (e) {
      SecureLogger.logError('Error uploading avatar', error: e);
      setState(() {
        _avatarError = 'An error occurred while uploading your avatar.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
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
          else ...[
            IconButton(
              onPressed: _loadProfileData,
              icon: const Icon(Icons.refresh, color: Color(0xFF4ECDC4)),
              tooltip: 'Refresh Profile Data',
            ),
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
        ],
      ),
      body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
            )
          : Form(
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

              _buildSectionTitle('Avatar'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: _selectedAvatarBytes != null
                        ? MemoryImage(_selectedAvatarBytes!)
                        : (_player?.avatarUrl != null && _player!.avatarUrl!.isNotEmpty
                            ? NetworkImage(_player!.avatarUrl!)
                            : null),
                    child: (_selectedAvatarBytes == null &&
                            (_player?.avatarUrl == null || _player!.avatarUrl!.isEmpty))
                        ? Text(
                            _player?.displayName
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                'P',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading || _isUploadingAvatar ? null : _pickAvatar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: Text(
                            _selectedAvatarBytes != null
                                ? 'Change Selected Image'
                                : 'Choose Image',
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _selectedAvatarBytes != null &&
                                  !_isUploadingAvatar &&
                                  !_isLoading
                              ? _uploadAvatar
                              : null,
                          icon: _isUploadingAvatar
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                                  ),
                                )
                              : const Icon(Icons.cloud_upload, color: Color(0xFF4ECDC4)),
                          label: Text(
                            _isUploadingAvatar ? 'Uploading...' : 'Upload Avatar',
                            style: const TextStyle(color: Color(0xFF4ECDC4)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4ECDC4)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accepted formats: PNG, JPG, JPEG, GIF, WebP • Max size 5MB.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        if (_selectedAvatarName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _selectedAvatarName!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_avatarError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _avatarError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],

              const SizedBox(height: 24),

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
