import 'package:flutter/material.dart';
import 'package:prep_mate/core/theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                  color: const Color(0xFF7C3AED).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? const Color(0xFFF59E0B) : textSecondary,
                  size: 22,
                ),
                onPressed: onBookmarkToggle,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: const Color(0xFFA78BFA), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 15, color: textSecondary),
              const SizedBox(width: 4),
              Text(time, style: TextStyle(color: textSecondary, fontSize: 12)),
              const SizedBox(width: 14),
              Icon(Icons.assignment_outlined, size: 15, color: textSecondary),
              const SizedBox(width: 4),
              Text(mcqs, style: TextStyle(color: textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}