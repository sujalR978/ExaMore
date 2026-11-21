import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/screens/admin_home_screen.dart';
import 'package:prep_mate/features/auth/screens/email_verification_screen.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/screens/onboarding_screen.dart';
import 'package:prep_mate/features/user/navigation/main_navigator.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _hasError = false;
  String _errorMessage = '';
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();

    // Start splash initialization sequence
    _initializeApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Probes network connectivity to verify internet access
  Future<bool> _checkInternetConnection() async {
    if (kIsWeb) return true;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final result2 = await InternetAddress.lookup('one.one.one.one')
            .timeout(const Duration(seconds: 4));
        return result2.isNotEmpty && result2[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Displays a modal dialog when no active internet connection is detected
  Future<void> _showNoInternetDialog() async {
    if (!mounted) return;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool isRetrying = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon with animated circle glow
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.wifi_off_rounded,
                          color: Color(0xFFEF4444),
                          size: 38,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Dialog Title
                    Text(
                      "No Internet Connection",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Dialog Description
                    Text(
                      "An active internet connection is required to launch ExaMore. Please check your Wi-Fi or cellular network settings and try again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: textSecondary,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Retry CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isRetrying
                            ? null
                            : () async {
                                setDialogState(() => isRetrying = true);
                                final bool hasNet =
                                    await _checkInternetConnection();
                                if (hasNet) {
                                  if (dialogCtx.mounted) {
                                    Navigator.of(dialogCtx).pop();
                                  }
                                  _initializeApp();
                                } else {
                                  setDialogState(() => isRetrying = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Still disconnected. Please check your connection.",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isRetrying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "Retry Connection",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Performs backend health check via Firestore
  Future<bool> _performBackendHealthCheck() async {
    try {
      // Lightweight probe to verify Firebase reachability
      await FirebaseFirestore.instance
          .collection('users')
          .limit(1)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initializeApp() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isOffline = false;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // 1. Internet connection check
      final bool hasInternet = await _checkInternetConnection();

      // Ensure minimum splash display before showing dialog or navigating
      final int elapsedCheckMs = stopwatch.elapsedMilliseconds;
      const int initialDisplayMs = 1500;
      if (elapsedCheckMs < initialDisplayMs) {
        await Future.delayed(
          Duration(milliseconds: initialDisplayMs - elapsedCheckMs),
        );
      }

      if (!mounted) return;

      if (!hasInternet) {
        setState(() {
          _isOffline = true;
        });
        await _showNoInternetDialog();
        return;
      }

      // 2. Initial configuration loading (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      // 3. Backend Health Check
      if (hasInternet) {
        await _performBackendHealthCheck();
      }

      // 4. Authentication and Role Verification
      final User? currentUser = FirebaseAuth.instance.currentUser;
      Widget destination;

      if (!onboardingCompleted) {
        // First-time user: Navigate to onboarding
        destination = const OnboardingScreen();
      } else if (currentUser == null) {
        // Logged-out user: Navigate to Login
        destination = const Login();
      } else {
        // Logged-in user: Verify active session & role
        try {
          if (hasInternet) {
            await currentUser.reload();
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-disabled' || e.code == 'user-not-found') {
            await FirebaseAuth.instance.signOut();
            destination = const Login();
          }
        } catch (_) {}

        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser == null) {
          destination = const Login();
        } else {
          // Check email verification guard
          final bool isGoogleAuth = refreshedUser.providerData
              .any((p) => p.providerId == 'google.com');

          String role = 'student';
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(refreshedUser.uid)
                .get();

            if (doc.exists) {
              final data = doc.data();
              role = (data?['role'] ?? 'student')
                  .toString()
                  .toLowerCase()
                  .trim();
            }
          } catch (_) {
            // Offline fallback to student role if Firestore read fails
            role = 'student';
          }

          if (!refreshedUser.emailVerified &&
              !isGoogleAuth &&
              role != 'super_admin') {
            destination = EmailVerificationScreen(
              email: refreshedUser.email,
              targetRole: role,
            );
          } else if (role == 'super_admin' || role == 'admin') {
            destination = const AdminHomeScreen();
          } else {
            destination = const MainNavigator();
          }
        }
      }

      // 5. Ensure minimum 3-second splash display for branding
      final int elapsedMs = stopwatch.elapsedMilliseconds;
      const int minimumSplashMs = 3000;
      if (elapsedMs < minimumSplashMs) {
        await Future.delayed(
          Duration(milliseconds: minimumSplashMs - elapsedMs),
        );
      }

      if (!mounted) return;

      // 6. Smooth navigation to resolved destination without returning to Splash
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage =
            'Initialization error: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF1E1B4B),
                    Color(0xFF0F172A),
                    Color(0xFF090D16),
                  ]
                : const [
                    Color(0xFFF8FAFC),
                    Color(0xFFEEF2F6),
                    Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo with glowing shadow container
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(
                                alpha: isDark ? 0.35 : 0.2,
                              ),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/image/examore_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/image/image.png',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => const Icon(
                                Icons.school_rounded,
                                size: 56,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Brand Title
                      Text(
                        "ExaMore",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Brand Tagline
                      Text(
                        "Smart Exams. Better Results.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Offline Banner indicator
                      if (_isOffline && !_hasError) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 16,
                                color: Color(0xFFF59E0B),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Offline Mode Enabled",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Loading indicator or Error state
                      if (_hasError) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _initializeApp,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text("Retry"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
