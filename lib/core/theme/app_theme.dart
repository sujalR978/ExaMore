import 'package:flutter/material.dart';

/// Centralized Theme Tokens and Configurations for ExaMore
class AppColors {
  // Brand accents
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryAmber = Color(0xFFF59E0B);
  static const Color accentLightPurple = Color(0xFFA78BFA);

  // Dark Theme Tokens (Existing Dark Palette)
  static const Color darkBackground = Color(0xFF0D121F);
  static const Color darkCard = Color(0xFF171E31);
  static const Color darkSurfaceSecondary = Color(0xFF13192B);
  static const Color darkBorder = Color(0xFF28334D);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Tokens (Professional Soft Palette)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Theme-aware helper getters
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color surfaceSecondary(bool isDark) => isDark ? darkSurfaceSecondary : lightSurfaceSecondary;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(bool isDark) => isDark ? darkTextMuted : lightTextMuted;
}

class AppTheme {
  // =========================
  // LIGHT THEME
  // =========================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.primaryPurple,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryAmber,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightTextPrimary,
      outline: AppColors.lightBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
    ),
  );

  // =========================
  // DARK THEME
  // =========================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.primaryPurple,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryPurple,
      secondary: AppColors.primaryAmber,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkTextPrimary,
      outline: AppColors.darkBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
    ),
  );
}
