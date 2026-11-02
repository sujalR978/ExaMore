import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/Auth/services/auth_service.dart';
import 'package:prep_mate/features/Auth/widgets/button.dart';
import 'package:prep_mate/features/Auth/widgets/filedTitle.dart';
import 'package:prep_mate/features/Auth/widgets/googleButton.dart';
import 'package:prep_mate/features/Auth/widgets/inputField.dart';
import 'package:prep_mate/features/Auth/widgets/mainTitle.dart';
import 'package:prep_mate/features/Auth/widgets/subTitle.dart';
import 'package:prep_mate/features/Auth/widgets/textButton.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();

  // FIXED TYPO: Changed _regis to _isRegistering for clarity
  bool _isRegistering = false;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _cPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
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

  // FIX: Success Pop-up Dialog & Navigation routing
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981), // Emerald Green
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Account Created!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your account has been created successfully. You can now log in to start your journey.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    // FIX: Wipes the navigation stack so they don't stay on the registration screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const Login()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED), // Brand purple
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue to Login",
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

  // FIXED TYPO: Changed _registor() to _register()
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isRegistering = true;
    });

    final String inputEmail = _email.text.trim().toLowerCase();
    final String inputName = _name.text.trim();
    final String inputPassword = _password.text.trim();

    try {
      // FIX: Explicit duplicate check against Cloud Firestore 'users' collection
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: inputEmail)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        _showError(
          'This email is already registered in our database. Please login instead.',
        );
        setState(() => _isRegistering = false);
        return;
      }

      // Create user with Auth Service
      final AuthService authService = AuthService();
      await authService.createUser(
        name: inputName,
        email: inputEmail,
        password: inputPassword,
      );

      if (!mounted) return;

      // Trigger the success pop-up instead of getting stuck!
      _showSuccessDialog();
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
    } catch (e) {
      _showError('Something went wrong: ${e.toString()}');
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                          color: const Color(
                            0xFF4C1D95,
                          ).withValues(alpha: isDark ? 0.10 : 0.04),
                        ),
                      ],
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xffE2E8F0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                width: 1,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xffE2E8F0),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/image/image.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.school,
                                        size: 40,
                                        color: Color(0xFF7C3AED),
                                      ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Maintitle(text: "Create your Examora"),
                          const Maintitle(text: "account"),
                          const SizedBox(height: 6),
                          const Subtitle(
                            text:
                                "Start your journey toward better exam results.",
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                              top: 24,
                              bottom: 24,
                              left: 24,
                              right: 24,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: const Googlebutton(),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 24,
                              right: 24,
                              left: 24,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xffCBC4D2),
                                    endIndent: 10,
                                  ),
                                ),
                                Text(
                                  "OR CONTINUE WITH",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xff7A7582),
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xffCBC4D2),
                                    indent: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Form(
                            key: _formKey,
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4.0),
                                      child: Filedtitle(text: "Full Name"),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Inputfield(
                                        controller: _name,
                                        hintText: "John Doe",
                                        icon: Icons.person,
                                        isPassword: false,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return "Full name is required";
                                          }
                                          if (value.trim().length < 3) {
                                            return "Enter a valid name";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4.0),
                                      child: Filedtitle(text: "Email Address"),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Inputfield(
                                        controller: _email,
                                        hintText: "student@university.edu",
                                        icon: Icons.email,
                                        isPassword: false,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return "Email is required";
                                          }
                                          final emailRegex = RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          );
                                          if (!emailRegex.hasMatch(
                                            value.trim(),
                                          )) {
                                            return "Enter a valid email address";
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4.0),
                                      child: Filedtitle(text: "Password"),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Inputfield(
                                        controller: _password,
                                        hintText: "••••••••",
                                        icon: Icons.lock,
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
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4.0),
                                      child: Filedtitle(
                                        text: "Confirm Password",
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: Inputfield(
                                        controller: _cPassword,
                                        hintText: "••••••••",
                                        icon: Icons.lock_outline,
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
                                    ),
                                    SizedBox(
                                      height: 52,
                                      width: double.infinity,
                                      child: Button(
                                        text: _isRegistering
                                            ? "Creating Account..."
                                            : "Create Account",
                                        icon: Icons.arrow_forward,
                                        onPressed: () {
                                          if (!_isRegistering) {
                                            _register();
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Subtitle(
                                          text: "Already have an account? ",
                                        ),
                                        Textbutton(
                                          text: "Login",
                                          onPressed: () {
                                            Navigator.of(
                                              context,
                                            ).pushReplacement(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const Login(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
