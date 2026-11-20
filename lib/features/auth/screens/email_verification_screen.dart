import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/screens/admin_home_screen.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/user/navigation/main_navigator.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;
  final String? targetRole;

  const EmailVerificationScreen({
    super.key,
    this.email,
    this.targetRole,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _pollingTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _isChecking = false;
  bool _isResending = false;
  bool _isNavigating = false;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userEmail = widget.email ?? _auth.currentUser?.email ?? '';
    _startVerificationPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned to the app: refresh & check immediately
      _checkEmailVerification(silent: true);
      _startVerificationPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // User left the app: stop background network polling to conserve battery & network
      _pollingTimer?.cancel();
    }
  }

  void _startVerificationPolling() {
    _pollingTimer?.cancel();
    // Poll every 4 seconds when app is actively open
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkEmailVerification(silent: true);
    });
  }

  Future<void> _checkEmailVerification({bool silent = false}) async {
    if (_isNavigating) return;

    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        if (!silent) {
          _showSnackBar(
            'Session expired. Please log in again.',
            isError: true,
          );
          _navigateToLogin();
        }
        return;
      }

      await user.reload();
      final User? refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        _pollingTimer?.cancel();
        _isNavigating = true;

        if (mounted) {
          _showSnackBar('Email successfully verified!', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) {
            await _routeToTargetDashboard(refreshedUser);
          }
        }
        return;
      } else {
        if (!silent && mounted) {
          _showSnackBar(
            'Email not verified yet. Please check your inbox and click the verification link.',
            isError: false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!silent && mounted) {
        _showSnackBar(
          e.message ?? 'Verification check failed. Please check your network.',
          isError: true,
        );
      }
    } catch (_) {
      if (!silent && mounted) {
        _showSnackBar(
          'Network connection issue. Please check your internet connection.',
          isError: true,
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _routeToTargetDashboard(User user) async {
    String role = widget.targetRole ?? 'student';

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        role = (doc.data()?['role'] ?? role).toString().toLowerCase().trim();
      }
    } catch (_) {}

    if (!mounted) return;

    if (role == 'super_admin' || role == 'admin') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigator()),
        (route) => false,
      );
    }
  }

  void _startCooldown([int seconds = 60]) {
    setState(() {
      _cooldownSeconds = seconds;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('No active session found. Please log in.', isError: true);
        _navigateToLogin();
        return;
      }

      await user.sendEmailVerification();
      _startCooldown(60);

      if (mounted) {
        _showSnackBar(
          'Verification email sent successfully! Please check your inbox.',
          isSuccess: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        _startCooldown(120);
        _showSnackBar(
          'Too many requests. Please wait a few moments before trying again.',
          isError: true,
        );
      } else {
        _showSnackBar(
          e.message ?? 'Failed to resend verification email.',
          isError: true,
        );
      }
    } catch (_) {
      _showSnackBar(
        'Unable to resend email. Please check your internet connection.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _navigateToLogin() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
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
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : isSuccess
                ? const Color(0xFF10B981)
                : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayEmail = _userEmail.isNotEmpty
        ? _userEmail
        : (_auth.currentUser?.email ?? 'your email');

    return Scaffold(
      backgroundColor: const Color(0xFF0D121F),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.85, 0.7),
            radius: 1.1,
            colors: [
              Color(0xFF2E1A68),
              Color(0xFF13192B),
              Color(0xFF0D121F),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF171E31),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF28334D),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. Compact Branding & Icon Header
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/image/examore_logo.png',
                            height: 65,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.school_rounded,
                              size: 48,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7C3AED).withOpacity(0.12),
                              border: Border.all(
                                color:
                                    const Color(0xFF7C3AED).withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_rounded,
                              size: 34,
                              color: Color(0xFFA78BFA),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // B. Main Heading & Subtitle
                    const Center(
                      child: Text(
                        "Verify Your Email",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        "We have sent a verification link to:",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // C. Email Address Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF192132),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: Color(0xFFA78BFA),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayEmail,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF8FAFC),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // D. Step-by-Step Instructions Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121826),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF28334D),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepItem(
                            number: "1",
                            text:
                                "Open your email inbox and look for an email from ExaMore.",
                          ),
                          const SizedBox(height: 10),
                          _buildStepItem(
                            number: "2",
                            text:
                                "Tap the verification link inside the email.",
                          ),
                          const SizedBox(height: 10),
                          _buildStepItem(
                            number: "3",
                            text:
                                "Return to this application. ExaMore will automatically detect your verification and continue.",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // E. Spam Warning Notice Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Can't find the email in your inbox? Please check your Spam or Junk folder as well.",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // F. Animated Verification Waiting Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF7C3AED).withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Waiting for verification...",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA78BFA),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // G. Primary Action Button: "I Have Verified My Email"
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            _isChecking ? null : () => _checkEmailVerification(),
                        child: _isChecking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "I Have Verified My Email",
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Color(0xFF0F172A),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // H. Secondary Action: Resend Verification Email with Cooldown
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF192132),
                          side: const BorderSide(
                            color: Color(0xFF334155),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: (_cooldownSeconds > 0 || _isResending)
                            ? null
                            : _resendVerificationEmail,
                        child: _isResending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _cooldownSeconds > 0
                                    ? "Resend Email (${_cooldownSeconds}s)"
                                    : "Resend Verification Email",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _cooldownSeconds > 0
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFF8FAFC),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // I. Log In with Different Account / Back to Login
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        onPressed: _navigateToLogin,
                        child: const Text(
                          "Wrong email address? Log in again",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA78BFA),
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

  Widget _buildStepItem({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7C3AED).withOpacity(0.2),
            border: Border.all(
              color: const Color(0xFF7C3AED).withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA78BFA),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

