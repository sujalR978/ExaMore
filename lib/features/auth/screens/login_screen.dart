import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_mate/core/utils/dialog_utils.dart';
import 'package:prep_mate/core/utils/validators.dart';
import 'package:prep_mate/features/admin/screens/admin_home_screen.dart';
import 'package:prep_mate/features/auth/screens/email_verification_screen.dart';
import 'package:prep_mate/features/auth/screens/forgot_password_screen.dart';
import 'package:prep_mate/features/auth/screens/registration_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/custom_text_button.dart';
import 'package:prep_mate/features/auth/widgets/google_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';
import 'package:prep_mate/features/user/navigation/main_navigator.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLogin = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showFriendlyToast(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.shade700
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 4,
      ),
    );
  }

  Future<bool> _hasInternetConnection() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    try {
      final lookup = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup(
          '1.1.1.1',
        ).timeout(const Duration(seconds: 3));
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> login() async {
    // Prevent duplicate triggers (LOG-007)
    if (_isLogin) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLogin = true;
    });

    // 1. Internet connection check (LOG-004)
    final bool hasNet = await _hasInternetConnection();
    if (!hasNet) {
      _showFriendlyToast(
        "No internet connection. Please check your network and try again.",
      );
      if (mounted) setState(() => _isLogin = false);
      return;
    }

    final String rawInput = _identifier.text.trim();
    final String passwordInput = _password.text;

    try {
      String emailToAuth = rawInput.toLowerCase();

      // Support 10-digit Phone Number lookup (LOG-001)
      if (RegExp(r'^\d{10}$').hasMatch(rawInput)) {
        try {
          final phoneQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: rawInput)
              .limit(1)
              .get();

          if (phoneQuery.docs.isEmpty) {
            _showFriendlyToast(
              "Account with this phone number is not registered yet, please sign up first.",
            );
            if (mounted) setState(() => _isLogin = false);
            return;
          }
          emailToAuth = (phoneQuery.docs.first.data()['email'] ?? '')
              .toString()
              .toLowerCase();
        } catch (_) {
          // If Firestore query is blocked, proceed with direct auth
        }
      }

      final AuthService authService = AuthService();

      final Map<String, dynamic> userData = await authService.signInUser(
        email: emailToAuth,
        password: passwordInput,
      );

      final String role = (userData['role'] ?? 'student')
          .toString()
          .toLowerCase();

      if (!mounted) return;

      // Role-based routing (LOG-011)
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

      // Friendly specific messages without generic "Invalid credentials" (LOG-002, LOG-003)
      if (e.code == 'user-not-found') {
        _showFriendlyToast(
          "Account with this email/phone is not registered yet, please sign up first.",
        );
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showFriendlyToast(
          "Incorrect password, please try again or use Forgot Password.",
        );
      } else if (e.code == 'email-not-verified') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                EmailVerificationScreen(email: _identifier.text.trim()),
          ),
        );
      } else if (e.code == 'invalid-email') {
        _showFriendlyToast("The email address is badly formatted.");
      } else if (e.code == 'user-disabled') {
        _showFriendlyToast(
          "This account has been disabled by an administrator.",
        );
      } else if (e.code == 'too-many-requests') {
        _showFriendlyToast(
          "Too many failed attempts. Please try again later or reset your password.",
        );
      } else if (e.code == 'network-request-failed') {
        _showFriendlyToast(
          "No internet connection. Please check your network and try again.",
        );
      } else {
        _showFriendlyToast(
          e.message ?? "An unexpected authentication error occurred.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showFriendlyToast(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textPrimary = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final textSecondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final gradientColors = isDark
        ? const [Color(0xFF2E1065), Color(0xFF1E1B4B), Color(0xFF0F172A)]
        : const [Color(0xFFEDE9FE), Color(0xFFF3E8FF), Color(0xFFF8FAFC)];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await DialogUtils.showExitConfirmation(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: 480,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Top Section: Logo & Branding Header (Balanced ~50% upper half)
                            Expanded(
                              child: SafeArea(
                                bottom: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/image/examore_logo.png',
                                          height: 150,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.school_rounded,
                                                    size: 68,
                                                    color: Color(0xFF8B5CF6),
                                                  ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 2. Bottom Sheet: Snug rounded container with form (no empty dead space below Google button)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                                border: Border(
                                  top: BorderSide(color: cardBorder, width: 1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.35 : 0.06,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    26,
                                    24,
                                    22,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Email or Phone Field Label (LOG-001)
                                        Text(
                                          "Email or Phone Number",
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Inputfield(
                                          controller: _identifier,
                                          hintText:
                                              "Enter email or 10-digit phone number",
                                          icon: Icons.person_outline_rounded,
                                          isPassword: false,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator:
                                              Validators.validateEmailOrPhone,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          "Password",
                                          style: TextStyle(
                                            color: textPrimary,
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
                                          keyboardType:
                                              TextInputType.visiblePassword,
                                          validator:
                                              Validators.validateBasicPassword,
                                        ),
                                        const SizedBox(height: 8),
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
                                        const SizedBox(height: 16),
                                        Button(
                                          text: "LOGIN",
                                          isLoading: _isLogin,
                                          isDisabled: _isLogin,
                                          onPressed: _isLogin ? null : login,
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                                Navigator.of(
                                                  context,
                                                ).pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Registration(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        const Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                thickness: 1,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 14,
                                              ),
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
                                        const SizedBox(height: 18),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
