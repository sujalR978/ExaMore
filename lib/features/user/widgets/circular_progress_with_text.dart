import 'package:flutter/material.dart';

class CustomCircularProgress extends StatelessWidget {
  final double progress;
  final String text;
  final double width;
  final double height;
  final double strokeWidth;
  final double circleSize;

  const CustomCircularProgress({
    super.key,
    required this.progress,
    required this.text,
    required this.width,
    required this.height,
    this.strokeWidth = 14.0,
    this.circleSize = 160.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: circleSize,
            height: circleSize,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              backgroundColor: isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark
                    ? const Color(0xFFAEC6F0)
                    : const Color(0xFFD1DFFC),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),

          Text(
            text,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFF1E1B4B),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}