import 'package:flutter/material.dart';

class Filedtitle extends StatelessWidget {
  final String text;

  const Filedtitle({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      ),
    );
  }
}