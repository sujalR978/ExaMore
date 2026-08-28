import 'package:flutter/material.dart';

class Filedtitle extends StatefulWidget {
  final String text;
  const Filedtitle({super.key, required this.text});

  @override
  State<Filedtitle> createState() => _FiledtitleState();
}

class _FiledtitleState extends State<Filedtitle> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xff0B1C30),
        fontSize: 14,
      ),
    );
  }
}
