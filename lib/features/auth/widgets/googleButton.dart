import 'package:flutter/material.dart';

import 'package:prep_mate/features/Auth/services/auth_service.dart';
import 'package:prep_mate/features/User/Navigator/mainNavigator.dart';

class Googlebutton extends StatefulWidget {
  const Googlebutton({super.key});

  @override
  State<Googlebutton> createState() => _GooglebuttonState();
}

class _GooglebuttonState extends State<Googlebutton> {
  bool _isLoading = false;

  // Helper method for User-Friendly Error Messages
  void _showErrorSnackBar(String error) {
    String friendlyMessage = "Google Sign-In failed. Please try again.";

    final errorString = error.toLowerCase();

    if (errorString.contains("sign_in_canceled") ||
        errorString.contains("canceled")) {
      // We don't want to show a big red error if they just clicked cancel
      return;
    } else if (errorString.contains("network_error") ||
        errorString.contains("network-request-failed")) {
      friendlyMessage = "No internet connection. Please check your network.";
    } else if (errorString.contains(
      "account-exists-with-different-credential",
    )) {
      friendlyMessage =
          "An account already exists with a different sign-in method.";
    } else if (errorString.contains("popup_closed_by_user")) {
      return;
    } else {
      friendlyMessage = error
          .replaceAll("Exception: ", "")
          .replaceAll(RegExp(r'\[.*?\] '), '')
          .replaceAll("PlatformException(", "")
          .trim();

      if (friendlyMessage.length > 60) {
        friendlyMessage = "An unexpected error occurred during Google Sign-In.";
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                friendlyMessage,
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

  // NEW: Pop-up dialog to confirm registration for new users
  Future<bool> _confirmRegistrationDialog() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Create New Account?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            "No existing Examora account was found for this Google email. Would you like to register and create a new account?",
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false), // User hit cancel
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true), // User hit register
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED), // Brand Purple
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Yes, Register",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false; // Default to false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          width: 1,
          color: theme.brightness == Brightness.dark
              ? const Color(0xff475569)
              : const Color(0xffCBC4D2),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _isLoading
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });

              try {
                final AuthService authService = AuthService();

                // Pass the confirmation dialog callback to the service
                await authService.singInWithGoogle(
                  onConfirmRegistration: _confirmRegistrationDialog,
                );

                if (!mounted) return;

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainNavigator(),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar(e.toString());
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading)
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurface,
              ),
            )
          else
            SizedBox(
              height: 20,
              width: 20,
              child: Image.asset('assets/icons/google.png'),
            ),
          const SizedBox(width: 13),
          Text(
            _isLoading ? "Please wait..." : "Continue with Google",
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
