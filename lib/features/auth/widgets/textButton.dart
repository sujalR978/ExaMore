import 'package:flutter/material.dart';

class Textbutton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  Textbutton({super.key, required this.text, required this.onPressed});

  @override
  State<Textbutton> createState() => _TextbuttonState();
}

class _TextbuttonState extends State<Textbutton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onPressed,
      // style: ButtonStyle(
      //   overlayColor: WidgetStatePropertyAll(Colors.transparent),
      // ),
      child: Text(
        widget.text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: Color(0xff4C1D95),
        ),
      ),
    );
  }
}
