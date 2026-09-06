import 'package:flutter/material.dart';

class Maintitle extends StatelessWidget {
  final String text;

  const Maintitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }
}
