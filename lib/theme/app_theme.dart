import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF7C3AED), // Premium Violet
      scaffoldBackgroundColor: const Color(0xFF0F111A), // Midnight background
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C3AED),
        secondary: Color(0xFF06B6D4), // Neon Cyan
        surface: Color(0xFF1E2235), // Dark Card/Surface
        error: Color(0xFFF43F5E), // Neon Red
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E2235),
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}
