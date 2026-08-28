import 'package:flutter/material.dart';

class Subtitle extends StatefulWidget {
  final String text;
  const Subtitle({super.key, required this.text});

  @override
  State<Subtitle> createState() => _SubtitleState();
}

class _SubtitleState extends State<Subtitle> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey[600], fontSize: 14),
    );
  }
}
