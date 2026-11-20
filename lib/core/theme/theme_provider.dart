import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveThemePreference(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode);
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    if (mode == ThemeMode.light) {
      _saveThemePreference('light');
    } else if (mode == ThemeMode.dark) {
      _saveThemePreference('dark');
    } else {
      _saveThemePreference('system');
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setDarkTheme();
    } else {
      setLightTheme();
    }
  }

  void setLightTheme() {
    setThemeMode(ThemeMode.light);
  }

  void setDarkTheme() {
    setThemeMode(ThemeMode.dark);
  }

  void setSystemTheme() {
    setThemeMode(ThemeMode.system);
  }
}
