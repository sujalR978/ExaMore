import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/auth/screens/email_verification_screen.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/field_title.dart';
import 'package:prep_mate/features/auth/widgets/google_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';
import 'package:prep_mate/features/auth/widgets/main_title.dart';
import 'package:prep_mate/features/auth/widgets/sub_title.dart';
import 'package:prep_mate/features/auth/widgets/custom_text_button.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  bool _isRegistering = false;

  // Role: 'student' or 'admin'
  String _selectedRole = 'student';

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _adminCode = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _cPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _adminCode.dispose();
    _password.dispose();
    _cPassword.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showVerificationSentDialog(String targetEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a verification link to:\n$targetEmail\n\nPlease check your inbox and verify your email before logging in.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const Login()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isRegistering = true;
    });

    final String inputEmail = _email.text.trim().toLowerCase();
    final String inputName = _name.text.trim();
    final String inputPassword = _password.text.trim();
    final String inputCode = _adminCode.text.trim();

    try {
      String? validatedAdminId;

      // -------------------------------------------------------------
      // 1. ADMIN REGISTRATION: Direct self-service educator signup
      // -------------------------------------------------------------
      if (_selectedRole == 'admin') {
        validatedAdminId = null;
      }

      // -------------------------------------------------------------
      // 2. STUDENT REGISTRATION: Optional Instructor Code/Email verification
      // -------------------------------------------------------------
      if (_selectedRole == 'student' && inputCode.isNotEmpty) {
        try {
          final adminDocById = await FirebaseFirestore.instance
              .collection('users')
              .doc(inputCode)
              .get();

          if (adminDocById.exists &&
              (adminDocById.data()?['role'] == 'admin' ||
                  adminDocById.data()?['role'] == 'super_admin')) {
            validatedAdminId = adminDocById.id;
          } else {
            final adminByEmailQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: inputCode.toLowerCase())
                .limit(1)
                .get();

            if (adminByEmailQuery.docs.isNotEmpty) {
              final data = adminByEmailQuery.docs.first.data();
              final role = (data['role'] ?? '').toString().toLowerCase();
              if (role == 'admin' || role == 'super_admin') {
                validatedAdminId = adminByEmailQuery.docs.first.id;
              } else {
                _showError(
                  'Invalid Admin Code / Email. Please enter a valid Instructor UID or Email.',
                );
                setState(() => _isRegistering = false);
                return;
              }
            } else {
              _showError(
                'Invalid Admin Code / Email. Please enter a valid Instructor UID or Email.',
              );
              setState(() => _isRegistering = false);
              return;
            }
          }
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            // Gracefully accept the instructor code to link, avoiding unauthenticated query failure
            validatedAdminId = inputCode;
          } else {
            rethrow;
          }
        }
      }

      // -------------------------------------------------------------
      // 3. Register user in Firebase Authentication & Firestore
      // -------------------------------------------------------------
      final AuthService authService = AuthService();
      await authService.createUser(
        name: inputName,
        email: inputEmail,
        password: inputPassword,
        role: _selectedRole,
        adminId: validatedAdminId,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            email: inputEmail,
            targetRole: _selectedRole,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError(
          'An account already exists with this email address. Please login instead.',
        );
      } else if (e.code == 'weak-password') {
        _showError(
          'The password provided is too weak. Please use at least 6 characters.',
        );
      } else if (e.code == 'invalid-email') {
        _showError('The email address format is invalid.');
      } else if (e.code == 'network-request-failed') {
        _showError('Network error. Please check your internet connection.');
      } else {
        _showError(e.message ?? 'Registration failed. Please try again.');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showError(
          'Permission denied. Please ensure your Firebase Firestore rules allow account creation.',
        );
      } else {
        _showError(e.message ?? 'Database error during registration.');
      }
    } catch (e) {
      _showError('Registration failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E1065),
                Color(0xFF1E1B4B),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    // 1. Top Section: Logo & Branding Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/image/examore_logo.png',
                            height: 85,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.school_rounded,
                              size: 65,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "ExaMore Register",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF8FAFC),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Join ExaMore to start your personalized exam journey",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Bottom Sheet: Dark rounded container with form
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFF334155),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role Selector Toggle
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: const Color(0xFF334155),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = 'student';
                                            _adminCode.clear();
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          decoration: BoxDecoration(
                                            color: _selectedRole == 'student'
                                                ? const Color(0xFF7C3AED)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: _selectedRole == 'student'
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_outline_rounded,
                                                size: 16,
                                                color: _selectedRole == 'student'
                                                    ? Colors.white
                                                    : const Color(0xFF94A3B8),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Student",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: _selectedRole == 'student'
                                                      ? Colors.white
                                                      : const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedRole = 'admin';
                                            _adminCode.clear();
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          decoration: BoxDecoration(
                                            color: _selectedRole == 'admin'
                                                ? const Color(0xFF7C3AED)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: _selectedRole == 'admin'
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.school_outlined,
                                                size: 16,
                                                color: _selectedRole == 'admin'
                                                    ? Colors.white
                                                    : const Color(0xFF94A3B8),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "Admin / Instructor",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: _selectedRole == 'admin'
                                                      ? Colors.white
                                                      : const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Full Name
                                    const Text(
                                      "Full Name",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Inputfield(
                                      controller: _name,
                                      hintText: "Enter your full name",
                                      icon: Icons.person_outline_rounded,
                                      isPassword: false,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return "Full name is required";
                                        }
                                        if (value.trim().length < 3) {
                                          return "Enter a valid name";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Email Address
                                    const Text(
                                      "Email Address",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Inputfield(
                                      controller: _email,
                                      hintText: "Enter your email address",
                                      icon: Icons.email_outlined,
                                      isPassword: false,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return "Email is required";
                                        }
                                        final emailRegex = RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        );
                                        if (!emailRegex.hasMatch(value.trim())) {
                                          return "Enter a valid email address";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Optional Instructor Code for Students
                                    if (_selectedRole == 'student') ...[
                                      const Text(
                                        "Instructor Code (Optional)",
                                        style: TextStyle(
                                          color: Color(0xFFF8FAFC),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Stack(
                                        alignment: Alignment.centerRight,
                                        children: [
                                          Inputfield(
                                            controller: _adminCode,
                                            hintText: "Instructor email or UID",
                                            icon: Icons.school_outlined,
                                            isPassword: false,
                                            validator: (value) => null,
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(right: 14),
                                            child: Tooltip(
                                              message:
                                                  "Enter instructor's email or UID to join their classroom cohort",
                                              child: Icon(
                                                Icons.info_outline_rounded,
                                                size: 18,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Password
                                    const Text(
                                      "Password",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Inputfield(
                                      controller: _password,
                                      hintText: "Enter your password",
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Password is required";
                                        }
                                        if (value.length < 6) {
                                          return "Password must be at least 6 characters";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Confirm Password
                                    const Text(
                                      "Confirm Password",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Inputfield(
                                      controller: _cPassword,
                                      hintText: "Re-enter your password",
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Confirm Password is required";
                                        }
                                        if (value != _password.text) {
                                          return "Passwords do not match";
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 22),

                                    // Create Account CTA Button
                                    Button(
                                      text: _isRegistering
                                          ? "CREATING ACCOUNT..."
                                          : "REGISTER",
                                      onPressed: () {
                                        if (!_isRegistering) {
                                          _register();
                                        }
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    // Login navigation prompt
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Already have an account? ",
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                        Textbutton(
                                          text: "Login",
                                          color: const Color(0xFFA78BFA),
                                          onPressed: () {
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) => const Login(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 22),

                                    // OR Divider
                                    const Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            thickness: 1,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 14),
                                          child: Text(
                                            "OR",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            thickness: 1,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 22),

                                    // Continue with Google
                                    const Googlebutton(),
                                  ],
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
