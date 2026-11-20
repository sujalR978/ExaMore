import 'package:flutter/material.dart';

class Inputfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final FormFieldValidator<String> validator;

  const Inputfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.isPassword,
    required this.validator,
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
    return TextFormField(
      obscureText: widget.isPassword && !isPasswordVisible,
      controller: widget.controller,
      focusNode: _focusNode,
      validator: widget.validator,
      style: const TextStyle(
        color: Color(0xFFF8FAFC),
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      cursorColor: const Color(0xFF8B5CF6),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIcon: Icon(
          widget.icon,
          size: 20,
          color: isFocused
              ? const Color(0xFFA78BFA)
              : const Color(0xFF64748B),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                splashRadius: 18,
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: isFocused
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF64748B),
                ),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF8B5CF6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
