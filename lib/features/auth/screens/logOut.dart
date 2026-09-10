import 'package:flutter/material.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/Auth/widgets/appBar.dart';
import 'package:prep_mate/features/Auth/widgets/mainTitle.dart';
import 'package:prep_mate/features/Auth/widgets/subTitle.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  void _handleLogout(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => Login()));
  }

  void _handleStayLoggedIn(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: CustomAppbar(text: "Account"),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24.0),

              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.0),

                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.15 : 0.02,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),

                  child: Center(
                    child: Icon(
                      Icons.school_outlined,
                      size: 45,
                      color: isDark
                          ? const Color(0xFFA78BFA)
                          : const Color(0xFF1E1B4B),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Maintitle(text: "Ready to take a \nbreak?"),

                const SizedBox(height: 16),

                Subtitle(
                  text:
                      'Your progress is saved. We\'ll be ready\nwhen you are.',
                ),

                const SizedBox(height: 40),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _handleLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBF24),
                      foregroundColor: const Color(0xFF1E1B4B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),

                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stay Logged In Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _handleStayLoggedIn(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.white : Color(0xFF7C3AED),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),

                    child: Text(
                      'Stay Logged In',
                      style: TextStyle(
                        color: isDark ? Colors.white : Color(0xFF7C3AED),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
