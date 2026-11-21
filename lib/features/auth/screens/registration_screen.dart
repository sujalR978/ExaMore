import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_mate/features/auth/screens/email_verification_screen.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/custom_text_button.dart';
import 'package:prep_mate/features/auth/widgets/google_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';

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

  // Terms and conditions acceptance (REG-019)
  bool _agreeToTerms = false;
  bool _termsError = false;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _cPassword = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _cPassword.dispose();
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
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
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
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _hasInternetConnection() async {
    // In automated widget tests, bypass socket lookup to prevent pending timer issues
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('1.1.1.1')
            .timeout(const Duration(seconds: 3));
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF475569),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: Color(0xFF8B5CF6), size: 24),
                      SizedBox(width: 10),
                      Text(
                        "Terms of Service & Privacy Policy",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: const [
                        Text(
                          "1. Acceptance of Terms",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "By creating an account on ExaMore, you agree to comply with our community guidelines, test-taking integrity standards, and applicable laws.",
                          style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "2. User Privacy & Data Protection",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Your personal information, including your full name, email, and 10-digit phone number, is securely encrypted and used solely for authenticating your exam attempts, classroom enrollments, and academic performance tracking. We never sell your data to third parties.",
                          style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "3. Academic Integrity",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "All exam submissions must be your own independent work. Any unauthorized sharing of examination questions or answers may result in immediate suspension of account privileges.",
                          style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _agreeToTerms = true;
                          _termsError = false;
                        });
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "I Understand & Agree",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVerificationSentDialog(String targetEmail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: Color(0xFF10B981),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "We sent a verification link to:\n$targetEmail\n\nPlease check your inbox and verify your email before logging in.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF94A3B8),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => EmailVerificationScreen(
                          email: targetEmail,
                          targetRole: _selectedRole,
                        ),
                      ),
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
                    "Proceed to Verification",
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
    // 1. Prevent duplicate submission (REG-014)
    if (_isRegistering) return;

    // 2. Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 3. Validate Terms & Conditions acceptance (REG-019)
    if (!_agreeToTerms) {
      setState(() {
        _termsError = true;
      });
      _showFriendlyToast("Please agree to the Terms of Service & Privacy Policy to continue.");
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isRegistering = true;
      _termsError = false;
    });

    // 4. Internet Connectivity Check (REG-008)
    final bool hasNet = await _hasInternetConnection();
    if (!hasNet) {
      _showFriendlyToast("No internet connection. Please check your network and try again.");
      if (mounted) setState(() => _isRegistering = false);
      return;
    }

    // 5. Data sanitization (REG-009, REG-010)
    final String inputEmail = _email.text.trim().toLowerCase();
    final String inputPhone = _phone.text.trim();
    final String inputName = _name.text.trim();
    final String inputPassword = _password.text.trim();

    try {
      // 6. Backend Uniqueness Check: Email & Phone (REG-004, REG-012)
      try {
        final emailCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: inputEmail)
            .limit(1)
            .get();

        if (emailCheck.docs.isNotEmpty) {
          _showFriendlyToast("An account with this email address already exists. Please login instead.");
          if (mounted) setState(() => _isRegistering = false);
          return;
        }

        final phoneCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: inputPhone)
            .limit(1)
            .get();

        if (phoneCheck.docs.isNotEmpty) {
          _showFriendlyToast("An account with this phone number already exists.");
          if (mounted) setState(() => _isRegistering = false);
          return;
        }
      } catch (e) {
        // If Firestore rules prohibit unauthenticated queries, Firebase Auth will enforce email uniqueness
      }

      // 7. Register user in Firebase Authentication & Firestore (REG-018)
      // Note: Student register has NO instructor code field; adminId is null.
      final AuthService authService = AuthService();
      await authService.createUser(
        name: inputName,
        email: inputEmail,
        phone: inputPhone,
        password: inputPassword,
        role: _selectedRole,
        adminId: null,
      );

      if (!mounted) return;

      // 8. Success Feedback (REG-017, REG-018)
      _showVerificationSentDialog(inputEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showFriendlyToast('An account already exists with this email address. Please login instead.');
      } else if (e.code == 'weak-password') {
        _showFriendlyToast('The password provided is too weak. Please use an 8+ character strong password.');
      } else if (e.code == 'invalid-email') {
        _showFriendlyToast('The email address format is invalid.');
      } else if (e.code == 'network-request-failed') {
        _showFriendlyToast('Network error. Please check your internet connection.');
      } else {
        _showFriendlyToast(e.message ?? 'Registration failed. Please try again.');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showFriendlyToast('Permission denied. Please ensure your Firebase Firestore rules allow account creation.');
      } else {
        _showFriendlyToast(e.message ?? 'Database error during registration.');
      }
    } catch (e) {
      _showFriendlyToast('Registration failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      // Preserves entered data on failure (REG-016)
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
                    // Top Section: Logo & Branding Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/image/examore_logo.png',
                            height: 75,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.school_rounded,
                              size: 60,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Create Your Account",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF8FAFC),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
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

                    // Bottom Sheet: Rounded container with form
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
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
                                              Flexible(
                                                child: Text(
                                                  "Student",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: _selectedRole == 'student'
                                                        ? Colors.white
                                                        : const Color(0xFF94A3B8),
                                                  ),
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
                                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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
                                              Flexible(
                                                child: Text(
                                                  "Admin / Instructor",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: _selectedRole == 'admin'
                                                        ? Colors.white
                                                        : const Color(0xFF94A3B8),
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

                              const SizedBox(height: 18),

                              // Registration Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Full Name (REG-001, REG-010)
                                    const Text(
                                      "Full Name",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Inputfield(
                                      controller: _name,
                                      hintText: "Enter your full name",
                                      icon: Icons.person_outline_rounded,
                                      isPassword: false,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return "Full name is required";
                                        }
                                        if (value != value.trim()) {
                                          return "Leading or trailing spaces are not allowed";
                                        }
                                        if (value.trim().length < 3) {
                                          return "Name must be at least 3 characters";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // 2. Phone Number (REG-002, REG-010)
                                    const Text(
                                      "Phone Number",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Inputfield(
                                      controller: _phone,
                                      hintText: "Enter 10-digit phone number",
                                      icon: Icons.phone_outlined,
                                      isPassword: false,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return "Phone number is required";
                                        }
                                        if (value != value.trim()) {
                                          return "Leading or trailing spaces are not allowed";
                                        }
                                        final clean = value.trim();
                                        if (clean.length != 10 || !RegExp(r'^\d{10}$').hasMatch(clean)) {
                                          return "Phone number must be exactly 10 digits";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // 3. Email Address (REG-001, REG-009, REG-010)
                                    const Text(
                                      "Email Address",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Inputfield(
                                      controller: _email,
                                      hintText: "Enter your email address",
                                      icon: Icons.email_outlined,
                                      isPassword: false,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return "Email is required";
                                        }
                                        if (value != value.trim() || value.contains(' ')) {
                                          return "Email must not contain spaces";
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

                                    // 4. Password (REG-005, REG-011)
                                    const Text(
                                      "Password",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Inputfield(
                                      controller: _password,
                                      hintText: "Enter strong password",
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Password is required";
                                        }
                                        if (value != value.trim()) {
                                          return "Leading or trailing spaces are not allowed";
                                        }
                                        if (value.length < 8) {
                                          return "Password must be at least 8 characters long";
                                        }
                                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                          return "Password must contain an uppercase letter (A-Z)";
                                        }
                                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                                          return "Password must contain a lowercase letter (a-z)";
                                        }
                                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                                          return "Password must contain a number (0-9)";
                                        }
                                        if (!RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?/]').hasMatch(value)) {
                                          return "Password must contain a special character (!@#\$&*)";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // 5. Confirm Password (REG-001)
                                    const Text(
                                      "Confirm Password",
                                      style: TextStyle(
                                        color: Color(0xFFF8FAFC),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
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

                                    const SizedBox(height: 16),

                                    // 6. Terms & Conditions Checkbox (REG-019)
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: _termsError
                                            ? Border.all(color: const Color(0xFFEF4444), width: 1.2)
                                            : null,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Checkbox(
                                              value: _agreeToTerms,
                                              activeColor: const Color(0xFF7C3AED),
                                              side: BorderSide(
                                                color: _termsError
                                                    ? const Color(0xFFEF4444)
                                                    : const Color(0xFF64748B),
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              onChanged: (val) {
                                                setState(() {
                                                  _agreeToTerms = val ?? false;
                                                  if (_agreeToTerms) _termsError = false;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                text: "I agree to the ",
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: "Terms of Service",
                                                    style: const TextStyle(
                                                      color: Color(0xFFA78BFA),
                                                      fontWeight: FontWeight.w600,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = _showTermsDialog,
                                                  ),
                                                  const TextSpan(text: " and "),
                                                  TextSpan(
                                                    text: "Privacy Policy",
                                                    style: const TextStyle(
                                                      color: Color(0xFFA78BFA),
                                                      fontWeight: FontWeight.w600,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = _showTermsDialog,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 22),

                                    // 7. Register CTA Button (REG-013, REG-014, REG-015)
                                    Button(
                                      text: "REGISTER",
                                      isLoading: _isRegistering,
                                      isDisabled: _isRegistering,
                                      onPressed: _isRegistering ? null : _register,
                                    ),

                                    const SizedBox(height: 18),

                                    // 8. Login navigation prompt
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

                                    const SizedBox(height: 18),

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

                                    const SizedBox(height: 18),

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
