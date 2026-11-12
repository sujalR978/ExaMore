import 'package:flutter/material.dart';

class Textbutton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const Textbutton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      // style: ButtonStyle(
      //   overlayColor: WidgetStatePropertyAll(Colors.transparent),
      // ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: theme.brightness == Brightness.dark
              ? const Color(0xFFA78BFA)
              : const Color(0xFF4C1D95),
        ),
      ),
    );
  }
}
