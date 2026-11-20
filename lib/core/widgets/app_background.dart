import 'package:flutter/material.dart';

/// Centralized, responsive background widget for ExaMore.
///
/// Places the branded educational background image behind [child]
/// while ensuring optimal scaling and position across mobile, tablet,
/// laptop, and desktop viewports without distortion or horizontal overflow.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base background fill matching the deep indigo tone
            const ColoredBox(color: Color(0xFF0D0A35)),

            // Responsive background illustration
            Positioned.fill(
              child: Image.asset(
                'assets/image/examore_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFF0D0A35)),
              ),
            ),

            // Content layer placed safely above the background
            child,
          ],
        );
      },
    );
  }
}
