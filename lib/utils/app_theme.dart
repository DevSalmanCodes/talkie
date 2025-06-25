import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData modernDarkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0E0F13),

    colorScheme: ColorScheme.dark(
      primary: Colors.grey,
      secondary: Colors.grey[100]!,
      surface: Color(0xFF1C1F26),
      onSurface: Color(0xFFD1D5DB),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Colors.white70, size: 24),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1F26),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
      bodySmall: TextStyle(color: Colors.grey, fontSize: 12),
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
