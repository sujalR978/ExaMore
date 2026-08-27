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
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                );
  }
}