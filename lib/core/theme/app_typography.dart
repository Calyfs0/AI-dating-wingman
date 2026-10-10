import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Script logo + clean modern UI type for the neon dating look.
abstract final class AppTypography {
  static TextStyle get brandScript => GoogleFonts.greatVibes(
        fontSize: 56,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: AppColors.neonPink,
      );

  static TextTheme textTheme() {
    final body = GoogleFonts.dmSansTextTheme();
    return body.copyWith(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.1,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.12,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.35,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.05,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.2,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.2,
        color: AppColors.textTertiary,
      ),
    );
  }
}
