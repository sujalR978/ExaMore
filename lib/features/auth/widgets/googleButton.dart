import 'package:flutter/material.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/Auth/services/auth_service.dart';

class Googlebutton extends StatelessWidget {
  const Googlebutton({super.key});

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
      onPressed: () async {
        try {
          final AuthService authService = AuthService();

          await authService.singInWithGoogle();

          if (!context.mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Login()),
          );
        } catch (e) {
          print("GOOGLE SIGN IN ERROR: $e");

          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: Image.asset('assets/icons/google.png'),
          ),
          const SizedBox(width: 13),
          SizedBox(
            child: Text(
              "Continue with Google",
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
