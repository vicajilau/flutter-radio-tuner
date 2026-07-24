import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Context extension for quick access to theme extension colors and system UI overlay styles.
extension ThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// Returns system UI overlay style with transparent status bar dynamically tuned to theme brightness.
  SystemUiOverlayStyle get systemUiOverlayStyle {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          );
  }
}

/// Custom ThemeExtension defining premium colors and gradients for the design system.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color primaryStart;
  final Color primaryEnd;
  final Color secondary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final LinearGradient primaryGradient;
  final LinearGradient glassGradient;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.primaryStart,
    required this.primaryEnd,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primaryGradient,
    required this.glassGradient,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? primaryStart,
    Color? primaryEnd,
    Color? secondary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    LinearGradient? primaryGradient,
    LinearGradient? glassGradient,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      primaryStart: primaryStart ?? this.primaryStart,
      primaryEnd: primaryEnd ?? this.primaryEnd,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      glassGradient: glassGradient ?? this.glassGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      primaryStart: Color.lerp(primaryStart, other.primaryStart, t)!,
      primaryEnd: Color.lerp(primaryEnd, other.primaryEnd, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      glassGradient: LinearGradient.lerp(
        glassGradient,
        other.glassGradient,
        t,
      )!,
    );
  }
}

/// Central design system class that defines colors, gradients,
/// typography, and dark/light theme configurations.
class AppTheme {
  // Modern ThemeExtension Colors

  static const AppColors darkColors = AppColors(
    background: Color(0xFF070A0F),
    surface: Color(0xFF0F1524),
    surfaceLight: Color(0xFF1B2336),
    primaryStart: Color(0xFF6366F1), // Indigo
    primaryEnd: Color(0xFF8B5CF6), // Violet
    secondary: Color(0xFF10B981), // Emerald
    accent: Color(0xFFF59E0B), // Amber
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glassGradient: LinearGradient(
      colors: [Colors.white12, Colors.white24],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const AppColors lightColors = AppColors(
    background: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE5E7EB),
    primaryStart: Color(0xFF4F46E5), // Indigo (slightly darker for contrast)
    primaryEnd: Color(0xFF7C3AED), // Violet (slightly darker for contrast)
    secondary: Color(0xFF059669), // Emerald (slightly darker for contrast)
    accent: Color(0xFFD97706), // Amber (slightly darker for contrast)
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF9CA3AF),
    primaryGradient: LinearGradient(
      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glassGradient: LinearGradient(
      colors: [Colors.black12, Colors.black26],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkColors.background,
      colorScheme: ColorScheme.dark(
        primary: darkColors.primaryStart,
        secondary: darkColors.secondary,
        surface: darkColors.surface,
      ),
      cardTheme: CardThemeData(
        color: darkColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      extensions: [darkColors],
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: darkColors.textPrimary,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: darkColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: darkColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightColors.background,
      colorScheme: ColorScheme.light(
        primary: lightColors.primaryStart,
        secondary: lightColors.secondary,
        surface: lightColors.surface,
      ),
      cardTheme: CardThemeData(
        color: lightColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      extensions: [lightColors],
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: lightColors.textPrimary,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: lightColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: lightColors.textMuted,
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
