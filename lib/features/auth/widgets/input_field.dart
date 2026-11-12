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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 308,
      child: TextFormField(
        obscureText: widget.isPassword && !isPasswordVisible,
        controller: widget.controller,
        focusNode: _focusNode,
        validator: widget.validator,
        textAlignVertical: TextAlignVertical.bottom,

        // Text color
        style: TextStyle(color: theme.colorScheme.onSurface),

        decoration: InputDecoration(
          hintText: widget.hintText,

          // Hint text color
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
          ),

          // Background color
          filled: true,
          fillColor: isFocused
              ? isDark
                    ? const Color(0xFF273449)
                    : const Color(0xFFEFF6FF)
              : isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF8FAFC),

          // Prefix icon
          prefixIcon: Icon(
            widget.icon,
            color: isFocused
                ? isDark
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF7C3AED)
                : isDark
                ? const Color(0xFF94A3B8)
                : Colors.grey,
          ),

          // Password visibility icon
          suffixIcon: widget.isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: isFocused
                        ? isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF7C3AED)
                        : isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey,
                  ),
                )
              : null,

          // Normal border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : Colors.transparent,
              width: 1,
            ),
          ),

          // Focused border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
