import 'package:flutter/material.dart';

class AppTheme {
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFF00E5FF); // Changed from Purple to Cyan match
  static const Color deepBlack = Color(0xFF121212);
  static const Color surfaceGrey = Color(0xFF1E1E1E);
  static const Color errorRed = Color(0xFFFF1744);
  static const Color successGreen = Color(0xFF00E676);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepBlack,
    primaryColor: neonCyan,
    colorScheme: const ColorScheme.dark(
      primary: neonCyan,
      secondary: neonPurple,
      surface: surfaceGrey,
      background: deepBlack,
      error: errorRed,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
    ),
    
    fontFamily: 'Inter', // Ensure this is added to pubspec if using local assets, or just rely on system for now.

    cardTheme: CardThemeData(
      color: surfaceGrey,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: neonCyan.withOpacity(0.2), // Glow effect
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonCyan,
        foregroundColor: Colors.black, // Text color
        elevation: 8,
        shadowColor: neonCyan.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.0),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonCyan, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white54),
    ),
  );
}
