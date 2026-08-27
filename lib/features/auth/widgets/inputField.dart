import 'package:flutter/material.dart';

class Inputfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  const Inputfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.isPassword,
  });

  @override
  State<Inputfield> createState() => _InputfieldState();
}

class _InputfieldState extends State<Inputfield> {
  final FocusNode _focusNode = FocusNode();

  bool isFocused = false;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.59,
      width: 308,

      child: TextField(
        obscureText: widget.isPassword && !isPasswordVisible,
        controller: widget.controller,
        focusNode: _focusNode,
        textAlignVertical: TextAlignVertical.bottom,
        decoration: InputDecoration(
          hintText: widget.hintText,

          // Background color
          filled: true,
          fillColor: isFocused
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),

          // Icon color
          prefixIcon: Icon(
            widget.icon,
            color: isFocused ? const Color(0xFF0052FF) : Colors.grey,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: isFocused ? const Color(0xFF0052FF) : Colors.grey,
                  ),
                )
              : null,

          // Normal border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.transparent, width: 1),
          ),

          // Focused border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0052FF), width: 1.5),
          ),
        ),
      ),
    );
  }
}
