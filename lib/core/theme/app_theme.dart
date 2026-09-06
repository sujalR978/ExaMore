import 'package:flutter/material.dart';

class AppTheme {
  // =========================
  // LIGHT THEME
  // =========================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    scaffoldBackgroundColor: const Color(0xFFF8FAFC),

    primaryColor: const Color(0xFF4C1D95),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4C1D95),
      secondary: Color(0xFF7C3AED),
      surface: Colors.white,
      onSurface: Color(0xFF1E1B4B),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1E1B4B)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1E1B4B),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
    ),
  );

  // =========================
  // DARK THEME
  // =========================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: const Color(0xFF0F172A),

    primaryColor: const Color(0xFF8B5CF6),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFA78BFA),
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFF8FAFC),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
      titleTextStyle: TextStyle(
        color: Color(0xFFF8FAFC),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 1.5),
      ),
    ),
  );
}
