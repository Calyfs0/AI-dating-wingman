import 'package:flutter/material.dart';

/// Centralized Wingman color tokens matched to the product mockups.
/// Near-black charcoal + restrained violet/lavender accent.
abstract final class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color backgroundElevated = Color(0xFF0C0C0F);
  static const Color surface = Color(0xFF121216);
  static const Color surfaceElevated = Color(0xFF1A1A20);
  static const Color surfaceHighlight = Color(0xFF23232B);
  static const Color border = Color(0xFF2C2C36);
  static const Color borderSubtle = Color(0xFF1E1E26);

  static const Color accent = Color(0xFFB794F4);
  static const Color accentSoft = Color(0xFFA78BFA);
  static const Color accentMuted = Color(0x33B794F4);
  static const Color accentDeep = Color(0xFF7C5CE0);
  static const Color accentGlow = Color(0x66B794F4);

  static const Color textPrimary = Color(0xFFF7F7F8);
  static const Color textSecondary = Color(0xFFA0A0AB);
  static const Color textTertiary = Color(0xFF6E6E78);
  static const Color textInverse = Color(0xFF0B0B0D);

  static const Color success = Color(0xFF5FCB9A);
  static const Color successMuted = Color(0x335FCB9A);
  static const Color warning = Color(0xFFE8A54B);
  static const Color warningMuted = Color(0x33E8A54B);
  static const Color danger = Color(0xFFE57373);
  static const Color dangerMuted = Color(0x33E57373);
  static const Color info = Color(0xFF6BA4E8);

  static const Color statusActive = Color(0xFF5FCB9A);
  static const Color statusWaiting = Color(0xFFE8A54B);
  static const Color statusQuiet = Color(0xFF6E6E78);

  static const Color shimmerBase = Color(0xFF16161C);
  static const Color shimmerHighlight = Color(0xFF24242E);

  static const Color overlay = Color(0xCC000000);
  static const Color scrim = Color(0x99000000);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E0E12), background],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4C1FF), accent, accentDeep],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE9D5FF), Color(0xFFB794F4), Color(0xFF7C5CE0)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF18181F), Color(0xFF111116)],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4C1FF), accent],
  );

  static const LinearGradient heroAtmosphere = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2A1F3D),
      Color(0xFF141018),
      Color(0xFF000000),
    ],
  );
}
