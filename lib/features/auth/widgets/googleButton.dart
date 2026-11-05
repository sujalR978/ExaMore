import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/adminHomeScreen.dart';
import 'package:prep_mate/features/Auth/services/auth_service.dart';
import 'package:prep_mate/features/User/Navigator/mainNavigator.dart';

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

  // Dialog that handles Instructor ID validation with inline feedback
  Future<String?> _promptInstructorCodeDialog() async {
    final TextEditingController codeController = TextEditingController();
    String? errorMessage;
    bool isValidating = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.school, color: Color(0xFF7C3AED)),
                  SizedBox(width: 10),
                  Text(
                    "Join Classroom",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "To link your exams, enter your Teacher's Instructor Code (UID) or registered Email:",
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      autocorrect: false,
                      enabled: !isValidating,
                      decoration: InputDecoration(
                        hintText: "Instructor UID or teacher@school.edu",
                        prefixIcon: const Icon(
                          Icons.vpn_key_outlined,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: errorMessage,
                        errorMaxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isValidating
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(null);
                        },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isValidating
                      ? null
                      : () async {
                          final input = codeController.text.trim();
                          if (input.isEmpty) {
                            setDialogState(() {
                              errorMessage =
                                  "Please enter an Instructor Code or Email.";
                            });
                            return;
                          }

                          setDialogState(() {
                            isValidating = true;
                            errorMessage = null;
                          });

                          try {
                            // 1. Check if input is a valid Admin UID
                            final adminDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(input)
                                .get();

                            if (adminDoc.exists) {
                              final role = (adminDoc.data()?['role'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              if (role == 'admin' || role == 'super_admin') {
                                if (context.mounted) {
                                  Navigator.of(dialogContext).pop(adminDoc.id);
                                }
                                return;
                              }
                            }

                            // 2. Check by Admin Email (single field query avoids composite index errors)
                            final queryByEmail = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .where('email', isEqualTo: input.toLowerCase())
                                .limit(1)
                                .get();

                            if (queryByEmail.docs.isNotEmpty) {
                              final data = queryByEmail.docs.first.data();
                              final role = (data['role'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              if (role == 'admin' || role == 'super_admin') {
                                if (context.mounted) {
                                  Navigator.of(
                                    dialogContext,
                                  ).pop(queryByEmail.docs.first.id);
                                }
                                return;
                              }
                            }

                            // If neither match
                            setDialogState(() {
                              errorMessage =
                                  "No instructor found with this ID or Email. Please check with your teacher.";
                              isValidating = false;
                            });
                          } catch (e) {
                            setDialogState(() {
                              errorMessage =
                                  "Verification error. Please check your internet connection.";
                              isValidating = false;
                            });
                          }
                        },
                  child: isValidating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final AuthService authService = AuthService();

      // Sign in and provide callback to prompt for Admin ID if this is a new student
      final Map<String, dynamic> session = await authService.singInWithGoogle(
        onGetAdminId: () async {
          return await _promptInstructorCodeDialog();
        },
      );

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/image/google_logo.png',
                  height: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata, size: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  "Continue with Google",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }
}
