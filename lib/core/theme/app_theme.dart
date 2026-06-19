import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system class that defines colors, gradients,
/// typography (Outfit & Inter), and dark theme configurations.
class AppTheme {
  // Premium Color Palette
  static const Color background = Color(0xFF070A0F);
  static const Color surface = Color(0xFF0F1524);
  static const Color surfaceLight = Color(0xFF1B2336);

  static const Color primaryStart = Color(0xFF6366F1); // Indigo
  static const Color primaryEnd = Color(0xFF8B5CF6); // Violet
  static const Color secondary = Color(
    0xFF10B981,
  ); // Emerald green (active status)
  static const Color accent = Color(0xFFF59E0B); // Amber (highlights)

  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Gradient helper
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white12],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryStart,
        secondary: secondary,
        surface: surface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
