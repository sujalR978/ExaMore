import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/screens/admin_home_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/user/navigation/main_navigator.dart';

class Googlebutton extends StatefulWidget {
  const Googlebutton({super.key});

  @override
  State<Googlebutton> createState() => _GooglebuttonState();
}

class _GooglebuttonState extends State<Googlebutton> {
  bool _isLoading = false;

  void _showFriendlyMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
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
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.shade700
            : const Color(0xFF1E1B4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final AuthService authService = AuthService();

      // Sign in and provide callback to prompt for Admin ID if this is a new student
      final Map<String, dynamic> session = await authService.signInWithGoogle();

      if (!mounted) return;

      final String role = (session['role'] ?? 'student')
          .toString()
          .toLowerCase();

      // Navigate directly to the corresponding screen
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
    } catch (e) {
      if (!mounted) return;

      final errorStr = e.toString();
      if (errorStr.contains('sign_in_canceled')) {
        _showFriendlyMessage(
          "Sign-in cancelled. An instructor code is required to join.",
        );
      } else if (errorStr.contains('network-request-failed')) {
        _showFriendlyMessage("No instructor found.", isError: true);
      } else {
        _showFriendlyMessage(
          "Google Sign-In failed. Please try again.",
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1E2638),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google.png',
                    height: 19,
                    width: 19,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Continue with Google",
                    style: TextStyle(
                      color: Color(0xFFF8FAFC),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
