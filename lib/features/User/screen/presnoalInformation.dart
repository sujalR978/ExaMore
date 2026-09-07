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
  final TextEditingController _nameController = TextEditingController(
    text: 'Alex Carter',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'alex.carter@university.edu',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+1 (555) 234-5678',
  );
  final TextEditingController _levelController = TextEditingController(
    text: 'Year 3',
  );
  final TextEditingController _majorController = TextEditingController(
    text: 'Science Major',
  );

  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _levelController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        if (_formKey.currentState!.validate()) {
          // Save changes logic here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          _isEditing = false;
        }
      } else {
        _isEditing = true;
      }
    });
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
                      onPressed: _toggleEditMode,
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
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
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
                    const SizedBox(height: 12),
                    Text(
                      'Tap edit icon to update your details',
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
                      label: 'Email Address',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      isEditing: _isEditing,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      validator: (val) => val == null || !val.contains('@')
                          ? 'Enter a valid email'
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
                      validator: (val) => val == null || val.length < 6
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
                    onPressed: _toggleEditMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      foregroundColor: const Color(0xFF1E1B4B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
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
