import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? height;

  const Button({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool effectivelyDisabled = isDisabled || isLoading || onPressed == null;

    return Semantics(
      button: true,
      enabled: !effectivelyDisabled,
      label: text,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: effectivelyDisabled
                ? [
                    const Color(0xFF475569).withValues(alpha: 0.6),
                    const Color(0xFF334155).withValues(alpha: 0.6),
                  ]
                : [
                    const Color(0xFF7C3AED),
                    const Color(0xFF6D28D9),
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: effectivelyDisabled
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: effectivelyDisabled ? null : onPressed,
            child: Container(
              constraints: BoxConstraints(minHeight: height ?? 50),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.center,
              child: isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "PROCESSING...",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF8FAFC),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 15,
                            color: effectivelyDisabled
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFFF8FAFC),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            icon,
                            size: 18,
                            color: effectivelyDisabled
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFFF8FAFC),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
