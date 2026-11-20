import 'package:flutter/material.dart';

class Textbutton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;

  const Textbutton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: color ?? const Color(0xFFA78BFA),
        ),
      ),
    );
  }
}
