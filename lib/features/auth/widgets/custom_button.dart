import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;

  const Button({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color(0xFF6D28D9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 18,
                    color: const Color(0xFFF8FAFC),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}