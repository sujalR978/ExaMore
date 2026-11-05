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
      // 1. ADMIN REGISTRATION VERIFICATION: Requires Super Admin UID or Email
      // -------------------------------------------------------------
      if (_selectedRole == 'admin') {
        if (inputCode.isEmpty) {
          _showError('Super Admin Authorization Code is required.');
          setState(() => _isRegistering = false);
          return;
        }

        // Hardcoded Super Admin credentials shortcut
        final bool isHardcodedSuperAdmin =
            inputCode.toLowerCase() == 'admin@gmail.com' ||
            inputCode == 'admin123';

        if (!isHardcodedSuperAdmin) {
          // Verify via Firestore document lookup by UID
          final superAdminDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(inputCode)
              .get();

          if (superAdminDoc.exists &&
              superAdminDoc.data()?['role'] == 'super_admin') {
            // Valid Super Admin UID
          } else {
            // Fallback: Check if they passed Super Admin's email
            final superAdminQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: inputCode.toLowerCase())
                .limit(1)
                .get();

            if (superAdminQuery.docs.isEmpty ||
                superAdminQuery.docs.first.data()['role'] != 'super_admin') {
              _showError(
                'Invalid Super Admin Code. Only authorized personnel can create Admin accounts.',
              );
              setState(() => _isRegistering = false);
              return;
            }
          }
        }
      }

      // -------------------------------------------------------------
      // 2. STUDENT REGISTRATION VERIFICATION: Requires Admin/SuperAdmin UID
      // -------------------------------------------------------------
      if (_selectedRole == 'student') {
        if (inputCode.isEmpty) {
          _showError('Instructor Code or Email is required for students.');
          setState(() => _isRegistering = false);
          return;
        }

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
              _showError('Invalid Admin Code / Email.');
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

      _showVerificationSentDialog(inputEmail);
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

                          // Role Selector Tab
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
                              left: 24,
                              right: 24,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'student'
                                              ? const Color(0xFF7C3AED)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Student",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _selectedRole == 'student'
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.white70
                                                        : const Color(
                                                            0xFF64748B,
                                                          )),
                                            ),
                                          ),
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'admin'
                                              ? const Color(0xFF7C3AED)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Admin / Instructor",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _selectedRole == 'admin'
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.white70
                                                        : const Color(
                                                            0xFF64748B,
                                                          )),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                              top: 20,
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

                                    // Dynamic Verification Field for Students & Admins
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4.0,
                                      ),
                                      child: Filedtitle(
                                        text: _selectedRole == 'admin'
                                            ? "Super Admin Authorization Code"
                                            : "Admin / Instructor Code or Email",
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Inputfield(
                                        controller: _adminCode,
                                        hintText: _selectedRole == 'admin'
                                            ? "Enter Super Admin UID or Email"
                                            : "admin_uid or teacher@school.edu",
                                        icon: _selectedRole == 'admin'
                                            ? Icons.security_outlined
                                            : Icons.school_outlined,
                                        isPassword: false,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return _selectedRole == 'admin'
                                                ? "Super Admin authorization code is required"
                                                : "Instructor code/email is required to link exams";
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
                                        hintText: "user@example.com",
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
