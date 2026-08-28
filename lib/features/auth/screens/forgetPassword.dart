import 'package:flutter/material.dart';
import 'package:prep_mate/features/Auth/widgets/appBar.dart';
import 'package:prep_mate/features/Auth/widgets/inputField.dart';
import 'package:prep_mate/features/Auth/widgets/mainTitle.dart';
import 'package:prep_mate/features/Auth/widgets/subTitle.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();


  bool _isEmailVerified = false;

  
  void _handleSubmit(BuildContext context) {
    if (!_isEmailVerified) {
     
      if (_formKey.currentState!.validate()) {
        setState(() {
        
          _isEmailVerified = true;
        });
      }
    } else {
      
      if (_formKey.currentState!.validate()) {
        
    
      }
    }
  }

  // Separate method for Back to Login button onPressed
  void _handleBackToLogin(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: CustomAppbar(text: "Reset Password"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                 
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_reset_outlined,
                        size: 45,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Maintitle(text: 'Forgot your\npassword?'),
                  const SizedBox(height: 16),
                  Subtitle(
                    text: _isEmailVerified
                        ? 'Email verified! Please enter your new password below.'
                        : 'Enter your email address below to verify your account.',
                  ),
                  const SizedBox(height: 28),

                  // Email Input Field (Disabled once verified so user can't change it mid-way)
                  Inputfield(
                    controller: _emailController,
                    hintText: "student@university.edu",
                    icon: Icons.email,
                    isPassword: false,
                    // If email is verified, lock the field
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Email is required";
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),

                  // Conditional New Password & Confirm Password Fields
                  if (_isEmailVerified) ...[
                    const SizedBox(height: 16),
                    Inputfield(
                      controller: _newPasswordController,
                      hintText: "New Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Inputfield(
                      controller: _confirmPasswordController,
                      hintText: "Confirm New Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Submit / Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _handleSubmit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFBBF24,
                        ), // Amber/Orange
                        foregroundColor: const Color(0xFF1E1B4B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isEmailVerified
                                ? Icons.check_circle_outline
                                : Icons.send_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isEmailVerified
                                ? 'Update Password'
                                : 'Verify Email',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back to Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _handleBackToLogin(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF7C3AED),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
