import 'package:flutter/material.dart';

class AfyaTheme {
  // Clinical Triage Color Palette (High-Contrast Material 3)
  static const Color primaryEmergency = Color(0xFFB71C1C); // Critical Alert Red
  static const Color highUrgency = Color(0xFFE65100);      // High Urgency Orange
  static const Color mediumUrgency = Color(0xFFF57F17);    // Medium Urgency Amber
  static const Color lowUrgency = Color(0xFF1B5E20);       // Routine / Low Green

  // UI Brand Colors (East Africa Warm & Clinical)
  static const Color seedTeal = Color(0xFF00695C);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color accentCoral = Color(0xFFFF6F61);
  static const Color surfaceDark = Color(0xFF12181F);
  static const Color surfaceCard = Color(0xFF1E2630);
  static const Color highContrastText = Color(0xFFFFFFFF);
  static const Color subText = Color(0xFFB0BEC5);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF26A69A),
        onPrimary: Colors.black,
        secondary: const Color(0xFFFF8A80),
        surface: surfaceDark,
        onSurface: highContrastText,
        error: primaryEmergency,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: highContrastText,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C3847), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: highContrastText,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: highContrastText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: highContrastText,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: subText,
          height: 1.4,
        ),
      ),
    );
  }

  // Helper method for urgency color
  static Color getUrgencyColor(String triageLevel) {
    switch (triageLevel.toUpperCase()) {
      case 'CRITICAL':
        return primaryEmergency;
      case 'HIGH':
        return highUrgency;
      case 'MEDIUM':
        return mediumUrgency;
      case 'LOW':
      default:
        return lowUrgency;
    }
  }
}
