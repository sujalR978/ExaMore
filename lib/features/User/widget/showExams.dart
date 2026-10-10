import 'package:flutter/material.dart';

class ExamCardWidget extends StatelessWidget {
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String title;
  final String description;
  final String time;
  final String mcqs;
  final IconData icon;
  final bool isBookmarked;
  final String buttonText;
  final Color buttonBgColor;
  final Color buttonTextColor;
  final VoidCallback onButtonPressed;
  final VoidCallback? onBookmarkToggle; // Added parameter

  const ExamCardWidget({
    super.key,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.title,
    required this.description,
    required this.time,
    required this.mcqs,
    required this.icon,
    this.isBookmarked = false,
    required this.buttonText,
    required this.buttonBgColor,
    required this.buttonTextColor,
    required this.onButtonPressed,
    this.onBookmarkToggle, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? const Color(0xFFFBBF24) : subtitleColor,
                  size: 22,
                ),
                onPressed: onBookmarkToggle,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: subtitleColor),
              const SizedBox(width: 4),
              Text(time, style: TextStyle(color: subtitleColor, fontSize: 12)),
              const SizedBox(width: 14),
              Icon(Icons.list_alt, size: 16, color: subtitleColor),
              const SizedBox(width: 4),
              Text(mcqs, style: TextStyle(color: subtitleColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBgColor,
                foregroundColor: buttonTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}