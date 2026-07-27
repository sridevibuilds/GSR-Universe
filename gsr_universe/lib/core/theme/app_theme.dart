// Core Design System & Branding Theme config
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Main Gradients
  static const Color gradientStart = Color(0xFF1E3C72);
  static const Color gradientEnd = Color(0xFF2A5298);

  // Role Color Themes (From reference images)
  static const Color adminPrimary = Color(0xFF0D6EFD);   // Royal Blue
  static const Color facultyPrimary = Color(0xFF198754); // Emerald Green
  static const Color parentPrimary = Color(0xFF6610F2);  // Indigo Purple

  // Status & Utility Colors
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFDC3545);
  static const Color textDark = Color(0xFF212529);
  static const Color textLight = Color(0xFF6C757D);
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color cardBackground = Colors.white;
  static const Color pageBackground = Color(0xFFF8F9FA);
  static const Color tableHeaderBg = Color(0xFFF1F3F5);

  // Soft shadows config
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        )
      ];

  // Global Linear Gradient
  static LinearGradient get brandGradient => const LinearGradient(
        colors: [gradientStart, gradientEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;

  static const SizedBox h4 = SizedBox(height: 4);
  static const SizedBox h8 = SizedBox(height: 8);
  static const SizedBox h12 = SizedBox(height: 12);
  static const SizedBox h16 = SizedBox(height: 16);
  static const SizedBox h20 = SizedBox(height: 20);
  static const SizedBox h24 = SizedBox(height: 24);
  static const SizedBox h32 = SizedBox(height: 32);

  static const SizedBox w4 = SizedBox(width: 4);
  static const SizedBox w8 = SizedBox(width: 8);
  static const SizedBox w12 = SizedBox(width: 12);
  static const SizedBox w16 = SizedBox(width: 16);
  static const SizedBox w20 = SizedBox(width: 20);
  static const SizedBox w24 = SizedBox(width: 24);
}

class AppRadius {
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.gradientStart,
      scaffoldBackgroundColor: AppColors.pageBackground,
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gradientStart, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textLight,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textLight.withOpacity(0.6),
        ),
      ),
      textTheme: TextTheme(
        // Outfit for Headers
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 18),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: AppColors.textDark, fontSize: 16),
        // Inter for Body and labels
        bodyLarge: GoogleFonts.inter(color: AppColors.textDark, fontSize: 14),
        bodyMedium: GoogleFonts.inter(color: AppColors.textLight, fontSize: 13),
        labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 12),
      ),
    );
  }
}
