import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Inputfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const Inputfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.isPassword,
    required this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<Inputfield> createState() => _InputfieldState();
}

class _InputfieldState extends State<Inputfield> {
  late final FocusNode _effectiveFocusNode;
  bool _ownsFocusNode = false;

  bool isFocused = false;
  bool isPasswordVisible = false;
  bool _hasBeenBlurred = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _effectiveFocusNode = widget.focusNode!;
    } else {
      _effectiveFocusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_effectiveFocusNode.hasFocus) {
      // User left this textfield (lost focus / blur)
      if (!_hasBeenBlurred) {
        setState(() {
          _hasBeenBlurred = true;
        });
      }
    }
    if (mounted) {
      setState(() {
        isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _effectiveFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show validation errors after the user leaves the textfield (REG-007)
    // or when the parent form triggers validation.
    final AutovalidateMode effectiveAutovalidateMode = widget.autovalidateMode ??
        (_hasBeenBlurred
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled);

    return TextFormField(
      obscureText: widget.isPassword && !isPasswordVisible,
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      validator: widget.validator,
      autovalidateMode: effectiveAutovalidateMode,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
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
                  isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
        errorMaxLines: 2,
        errorStyle: const TextStyle(
          color: Color(0xFFF87171),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
