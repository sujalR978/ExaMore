import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  String _photoUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';
  String? _selectedImagePath; // Stores the local file path of the picked image

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _levelController.text = data['academicLevel'] ?? 'Year 3';
          _majorController.text = data['major'] ?? 'Science Major';
          _photoUrl = data['photoUrl'] ?? _photoUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _emailController.text = user.email ?? '';
          _nameController.text = user.displayName ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _levelController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  // Pick an image from gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        final length = await pickedFile.length();
        // Validate image size <= 5MB (PRF-010)
        if (length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected photo exceeds 5MB size limit. Please choose a smaller image.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        // Validate image file format (PRF-010)
        final ext = pickedFile.name.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unsupported file format. Please upload JPG, PNG, or WEBP.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _selectedImagePath = base64String;
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Photo library access is required to update your profile photo.\n\nIf permanently denied, you can re-enable access anytime in Device Settings > Apps > ExaMore > Permissions.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _saveDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_draft_name', _nameController.text);
      await prefs.setString('profile_draft_phone', _phoneController.text);
      await prefs.setString('profile_draft_level', _levelController.text);
      await prefs.setString('profile_draft_major', _majorController.text);
    } catch (_) {}
  }

  Future<void> _clearDraftLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_draft_name');
      await prefs.remove('profile_draft_phone');
      await prefs.remove('profile_draft_level');
      await prefs.remove('profile_draft_major');
    } catch (_) {}
  }

  Future<bool> _showDiscardChangesDialog() async {
    final theme = Theme.of(context);
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'You have uncommitted changes to your profile. Leaving this screen will discard them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedImagePath = null;
    });
    _clearDraftLocally();
    _loadUserData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes discarded.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Use the newly picked local image path if available, otherwise keep the old one
      String finalPhotoUrl = _selectedImagePath ?? _photoUrl;

      // Update Firestore user document
      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'academicLevel': _levelController.text.trim(),
        'major': _majorController.text.trim(),
        'photoUrl': finalPhotoUrl,
        'updatedAt': DateTime.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updatedData, SetOptions(merge: true));

      await _clearDraftLocally();

      setState(() {
        _photoUrl = finalPhotoUrl;
        _isEditing = false;
        _isSaving = false;
      });

      if (!mounted) return;

      // Show Success Pop-up Dialog instead of bottom notification
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: const Text(
            'Your profile information has been updated successfully!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text('Failed to update profile: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() {
        _isEditing = true;
      });
      _saveDraftLocally();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _showDiscardChangesDialog();
        if (discard && mounted) {
          _cancelEditing();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        // Capsule-shaped Top Bar
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(75),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () async {
                        if (_isEditing) {
                          final discard = await _showDiscardChangesDialog();
                          if (discard && mounted) {
                            _cancelEditing();
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  title: Text(
                    'Personal Information',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                        tooltip: 'Cancel Edit',
                        onPressed: _isSaving ? null : _cancelEditing,
                      ),
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.check : Icons.edit_outlined,
                        color: const Color(0xFFFBBF24),
                      ),
                      tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
                      onPressed: _isSaving ? null : _toggleEditMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section with Image Picker
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: _selectedImagePath != null || _photoUrl.isNotEmpty
                                  ? AppImageView(
                                      imageSource: _selectedImagePath ?? _photoUrl,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                      placeholder: Container(
                                        color: const Color(0xFF4C1D95),
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.person, color: Colors.white, size: 48),
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFF4C1D95),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.person, color: Colors.white, size: 48),
                                    ),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFBBF24),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF1E1B4B),
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing
                          ? 'Tap image to select new photo'
                          : 'Tap edit icon to update your details',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Information Fields Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline,
                      isEditing: _isEditing,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.name,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Name cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Email Address (Read-Only)',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      isEditing: false,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      isEditing: _isEditing,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.phone,
                      validator: (val) =>
                          val != null && val.isNotEmpty && val.length < 6
                          ? 'Enter a valid phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Academic Level',
                      controller: _levelController,
                      icon: Icons.school_outlined,
                      isEditing: _isEditing,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.text,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Level cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Major',
                      controller: _majorController,
                      icon: Icons.science_outlined,
                      isEditing: _isEditing,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.text,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Major cannot be empty'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Save Changes & Cancel Action Buttons (Visible only when editing)
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _cancelEditing,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDarkMode ? const Color(0xFF64748B) : Colors.grey.shade400,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : const Color(0xFF334155),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBF24),
                            foregroundColor: const Color(0xFF1E1B4B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: isEditing,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isEditing ? const Color(0xFF8B5CF6) : subtitleColor,
              size: 20,
            ),
            filled: true,
            fillColor: isEditing
                ? (isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC))
                : Colors.transparent,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF7C3AED),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }
}
