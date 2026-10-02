import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _photoUrlController = TextEditingController(); // Controller for image URL input

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  String _photoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _levelController.text = data['academicLevel'] ?? 'Year 3';
          _majorController.text = data['major'] ?? 'Science Major';
          _photoUrl = data['photoUrl'] ?? _photoUrl;
          _photoUrlController.text = _photoUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _emailController.text = user.email ?? '';
          _nameController.text = user.displayName ?? '';
          _photoUrlController.text = _photoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
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
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Use the URL from the text field or keep the old one
      String finalPhotoUrl = _photoUrlController.text.trim().isNotEmpty
          ? _photoUrlController.text.trim()
          : _photoUrl;

      // Update Firestore user document directly
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

      setState(() {
        _photoUrl = finalPhotoUrl;
        _isEditing = false;
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully in Firestore!')),
      );
    } catch (e) {
      print("Error updating profile: $e");
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
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

    return Scaffold(
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
                    onPressed: () => Navigator.pop(context),
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
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.check : Icons.edit_outlined,
                        color: const Color(0xFFFBBF24),
                      ),
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
              // Profile Picture Preview Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_photoUrl),
                      onBackgroundImageError: (_, __) => const Icon(Icons.person),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEditing ? 'Update profile image URL below' : 'Tap edit icon to update your details',
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
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Profile Image URL',
                      controller: _photoUrlController,
                      icon: Icons.image_outlined,
                      isEditing: _isEditing,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Image URL cannot be empty'
                          : null,
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
                      validator: (val) => val != null && val.isNotEmpty && val.length < 6
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Major cannot be empty'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Save Changes Action Button (Visible only when editing)
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
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
              const SizedBox(height: 30),
            ],
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