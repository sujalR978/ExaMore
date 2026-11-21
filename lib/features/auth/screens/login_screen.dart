import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/screens/admin_home_screen.dart';
import 'package:prep_mate/features/auth/screens/email_verification_screen.dart';
import 'package:prep_mate/features/auth/screens/forgot_password_screen.dart';
import 'package:prep_mate/features/auth/screens/registration_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/google_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';
import 'package:prep_mate/features/auth/widgets/custom_text_button.dart';
import 'package:prep_mate/features/user/navigation/main_navigator.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLogin = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
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
        elevation: 4,
      ),
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLogin = true;
    });

    try {
      final AuthService authService = AuthService();

      final Map<String, dynamic> userData = await authService.signInUser(
        email: _email.text.trim(),
        password: _password.text,
      );

      final String role = (userData['role'] ?? 'student')
          .toString()
          .toLowerCase();

      if (!mounted) return;

      // 3-Tier Routing
      if (role == 'super_admin' || role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        );
      } else {
        // Regular Student
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigator()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'user-not-found') {
        _showErrorSnackBar("Email is not registered.");
      } else if (e.code == 'wrong-password') {
        _showErrorSnackBar("Incorrect password.");
      } else if (e.code == 'email-not-verified') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _email.text.trim(),
            ),
          ),
        );
      } else if (e.code == 'invalid-email') {
        _showErrorSnackBar("The email address is badly formatted.");
      } else if (e.code == 'user-disabled') {
        _showErrorSnackBar(
          "This account has been disabled by an administrator.",
        );
      } else if (e.code == 'too-many-requests') {
        _showErrorSnackBar("Too many failed attempts. Please try again later.");
      } else if (e.code == 'network-request-failed') {
        _showErrorSnackBar(
          "No internet connection. Please check your network.",
        );
      } else {
        _showErrorSnackBar(
          e.message ?? "An unexpected authentication error occurred.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        e
            .toString()
            .replaceAll("Exception: ", "")
            .replaceAll(RegExp(r'\[.*?\] '), ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLogin = false;
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/image/examore_logo.png',
                            height: 95,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.school_rounded,
                              size: 70,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "ExaMore Login",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF8FAFC),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Master your exams and elevate your learning",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
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
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Address Field Label
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
                                      return "Enter a valid email";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Password Field Label
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

                                const SizedBox(height: 10),

                                // Forgot Password link aligned right
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Textbutton(
                                    text: "Forgot Password?",
                                    color: const Color(0xFFA78BFA),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Login CTA Button
                                Button(
                                  text: _isLogin ? "LOGGING IN..." : "LOGIN",
                                  onPressed: () {
                                    if (!_isLogin) login();
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Register navigation prompt
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Textbutton(
                                      text: "Register",
                                      color: const Color(0xFFA78BFA),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const Registration(),
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

                                // Sign in with Google
                                const Googlebutton(),
                              ],
                            ),
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
