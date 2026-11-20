import 'package:flutter/material.dart';
import 'package:prep_mate/core/theme/app_theme.dart';

/// Standard unified top AppBar component for the entire ExaMore Admin Panel.
///
/// Features:
/// - Consistent height (58dp)
/// - Extreme left sidebar hamburger toggle button (or optional back button for drill-down screens)
/// - Properly aligned title and optional subtitle/breadcrumb with typography tokens
/// - Page-specific right action buttons
/// - Seamless Light & Dark theme support using AppColors tokens
/// - Subtle bottom border divider for clean separation
class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const AdminTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuPressed,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(58.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = AppColors.background(isDark);
    final surfaceColor = isDark ? const Color(0xFF13192B) : Colors.white;
    final borderColor = AppColors.border(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final subtitleColor = AppColors.textSecondary(isDark);

    Widget? effectiveLeading;
    if (leading != null) {
      effectiveLeading = leading;
    } else if (showBackButton) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        color: textColor,
        tooltip: 'Back',
        splashRadius: 22,
        onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      );
    } else if (onMenuPressed != null) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.menu_rounded, size: 24),
        color: textColor,
        tooltip: 'Toggle Navigation Menu',
        splashRadius: 22,
        onPressed: onMenuPressed,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58.0,
          child: Row(
            children: [
              // Extreme Left: Navigation Button (Menu or Back)
              if (effectiveLeading != null) ...[
                const SizedBox(width: 4),
                effectiveLeading,
                const SizedBox(width: 4),
              ] else
                const SizedBox(width: 16),

              // Title and optional subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right Actions
              if (actions != null && actions!.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
                const SizedBox(width: 8),
              ] else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

