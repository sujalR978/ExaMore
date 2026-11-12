import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const Button({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Amber CTA color
        backgroundColor: const Color(0xFFF59E0B),

        // Text and icon color
        foregroundColor: const Color(0xFF0B1C30),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      onPressed: onPressed,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFF0B1C30),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 13),

          SizedBox(
            height: 20,
            width: 20,
            child: Icon(
              icon,
              color: const Color(0xFF0B1C30),
            ),
          ),
        ],
      ),
    );
  }
}