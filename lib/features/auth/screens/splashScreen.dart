import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => const Login()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 240, 240, 240),
              Color.fromARGB(255, 242, 241, 244),
            ],
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,

              padding: const EdgeInsets.all(4),

              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 4, 4, 4),
                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/image/image.png', fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 24),

            // App name
            const Text(
              "Examora",
              style: TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            const Text(
              "Smart Exams. Better Results.",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 50),

            // Loading indicator
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color.fromARGB(255, 9, 8, 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
