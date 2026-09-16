import 'package:flutter/material.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/Auth/services/auth_service.dart';
import 'package:prep_mate/features/User/Navigator/mainNavigator.dart';
import 'package:prep_mate/features/User/screen/userHomeScreen.dart';

class Googlebutton extends StatefulWidget {
  const Googlebutton({super.key});

  @override
  State<Googlebutton> createState() => _GooglebuttonState();
}

class _GooglebuttonState extends State<Googlebutton> {
  bool _isLoading = false;

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
          ? null // Disable button while loading
          : () async {
              setState(() {
                _isLoading = true;
              });

              try {
                final AuthService authService = AuthService();

                await authService.singInWithGoogle();

                if (!context.mounted) return;

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainNavigator(),
                  ),
                );
              } catch (e) {
                print("GOOGLE SIGN IN ERROR: $e");

                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              } finally {
                // Ensure loading state is reset if navigation didn't happen
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
            _isLoading ? "Signing in..." : "Continue with Google",
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
