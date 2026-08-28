import 'package:flutter/material.dart';

class Maintitle extends StatefulWidget {
  final String text;
  const Maintitle({super.key, required this.text});

  @override
  State<Maintitle> createState() => _MaintitleState();
}

class _MaintitleState extends State<Maintitle> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF1E1B4B),
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }
}
