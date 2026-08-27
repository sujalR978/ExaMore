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
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
    );
  }
}
