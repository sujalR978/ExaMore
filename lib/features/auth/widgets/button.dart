import 'package:flutter/material.dart';

class Button extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  const Button({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xffF59E0B),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: widget.onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 24,
                color: Color(0xff0B1C30),
                fontWeight: FontWeight(600),
              ),
            ),
          ),
          SizedBox(width: 13),
          SizedBox(
            height: 20,
            width: 20,
            child: Icon(widget.icon, color: Color(0xff0B1C30)),
          ),
        ],
      ),
    );
  }
}
