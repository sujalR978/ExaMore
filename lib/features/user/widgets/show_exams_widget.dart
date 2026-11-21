import 'package:flutter/material.dart';
import 'package:prep_mate/core/theme/app_theme.dart';

class ExamCardWidget extends StatelessWidget {
  final String badgeText;
  final String title;
  final String time;
  final String mcqs;
  final String marks;
  final String statusText;
  final bool isUpcoming;
  final bool isBookmarked;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onTap;

  // Optional styling properties (kept for backwards compatibility)
  final Color? badgeColor;
  final Color? badgeTextColor;
  final String? description;
  final IconData? icon;
  final Color? buttonBgColor;
  final Color? buttonTextColor;

  const ExamCardWidget({
    super.key,
    required this.badgeText,
    required this.title,
    required this.time,
    required this.mcqs,
    this.marks = '',
    this.statusText = '',
    this.isUpcoming = false,
    this.isBookmarked = false,
    required this.buttonText,
    required this.onButtonPressed,
    this.onBookmarkToggle,
    this.onTap,
    this.badgeColor,
    this.badgeTextColor,
    this.description,
    this.icon,
    this.buttonBgColor,
    this.buttonTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final textMuted = AppColors.textMuted(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUpcoming
              ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.4)
              : borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap ?? onButtonPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Subject Pill + Status Pill + Bookmark Button
                Row(
                  children: [
                    // Subject Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA78BFA),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Pill (Upcoming or Available)
                    if (statusText.isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isUpcoming
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                : const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isUpcoming
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                  : const Color(0xFF10B981).withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUpcoming
                                    ? Icons.schedule_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 11,
                                color: isUpcoming
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  statusText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isUpcoming
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Bookmark Button
                    IconButton(
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isBookmarked
                            ? const Color(0xFFF59E0B)
                            : textMuted,
                        size: 20,
                      ),
                      onPressed: onBookmarkToggle,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Middle: Exam Title
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),

                // Bottom Row: Metadata Chips (Left) + Action CTA (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Metadata inline
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(color: textMuted, fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.assignment_outlined,
                            size: 13,
                            color: textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mcqs,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (marks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(color: textMuted, fontSize: 10),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              marks,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Action Button
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUpcoming
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.16)
                              : const Color(0xFF7C3AED),
                          foregroundColor: isUpcoming
                              ? const Color(0xFFF59E0B)
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: isUpcoming
                                ? const BorderSide(
                                    color: Color(0xFFF59E0B),
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isUpcoming
                                ? const Color(0xFFF59E0B)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
